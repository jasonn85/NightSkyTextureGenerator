//
//  StarCatalogue.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/21/26.
//

import Foundation

struct StarCatalogue {
    let epoch: Date
    let magnitudeCount: Int
    let stars: [Star]
    
    struct Star {
        let catalogueNumber: Float
        let rightAscension: Double
        let declination: Double
        let spectralType: SpectralType?
        let magnitude: Double
        let rightAscensionProperMotion: Float?
        let declinationProperMotion: Float?
        let radialVelocity: Double?
        
        struct SpectralType: Equatable {
            let starClass: StarClass
            let refinement: Int
            
            enum StarClass: Character {
                case o = "O"
                case b = "B"
                case a = "A"
                case f = "F"
                case g = "G"
                case k = "K"
                case m = "M"
            }
        }
    }
}

extension StarCatalogue.Star.SpectralType {
    init?(fromData data: Data) {
        guard let string = String(data: data, encoding: .ascii),
              string.count >= 2,
              let starClass = StarClass(rawValue: string[string.index(string.startIndex, offsetBy: 0)]),
              let refinement = Int(String(string[string.index(string.startIndex, offsetBy: 1)])) else {
            return nil
        }
        
        self = StarCatalogue.Star.SpectralType(starClass: starClass, refinement: refinement)
    }
}

extension StarCatalogue {
    struct Header {
        static let length = 28
        
        let sequenceStart: Int
        let firstStarNumber: Int
        let starCount: Int
        let starIdType: StarIdType
        let properMotionInclude: ProperMotion
        let magnitudeCount: Int
        let bytesPerStarEntry: Int
        let epochType: StarEpoch
        
        enum StarIdType: Int {
            case noIds = 0
            case inCatalogue = 1
            case gscRegion = 2
            case tychoRegion = 3
            case integer = 4
        }
        
        enum ProperMotion: Int {
            case none = 0
            case properMotion = 1
            case radialVelocity = 2
        }
        
        init(fromData data: Data) {
            self.sequenceStart = Int(fromFourBytesLittleEndian: data.subdata(in: 0..<4))
            self.firstStarNumber = Int(fromFourBytesLittleEndian: data.subdata(in: 4..<8))
            let starCount = Int(fromFourBytesLittleEndian: data.subdata(in: 8..<12))
            self.epochType = starCount > 0 ? .b1950 : .j2000
            self.starCount = abs(starCount)
            self.starIdType = StarIdType(rawValue: Int(fromFourBytesLittleEndian: data.subdata(in: 12..<16))) ?? .noIds
            self.properMotionInclude = ProperMotion(rawValue: Int(fromFourBytesLittleEndian: data.subdata(in: 16..<20))) ?? .none
            self.magnitudeCount = abs(Int(fromFourBytesLittleEndian: data.subdata(in: 20..<24)))
            self.bytesPerStarEntry = Int(fromFourBytesLittleEndian: data.subdata(in: 24..<28))
        }
    }
    
    enum StarEpoch {
        case j2000
        case b1950
        
        var epochDate: Date {
            switch self {
            case .j2000:
                return Date(timeIntervalSince1970: 946684800)
            case .b1950:
                return Date(timeIntervalSince1970: -631152000)
            }
        }
    }
    
    init(fromBinaryData data: Data) {
        let header = Header(fromData: data)
        self.epoch = header.epochType.epochDate
        self.magnitudeCount = abs(header.magnitudeCount)
        
        var stars: [Star] = []
        
        for starIndex in 0..<header.starCount {
            let start = Header.length + starIndex * header.bytesPerStarEntry
            let end = start + header.bytesPerStarEntry
            stars.append(Star(fromData: data.subdata(in: start..<end)))
        }
        
        self.stars = stars
    }
}

extension StarCatalogue.Star {
    init(fromData data: Data) {
        self.catalogueNumber = Float(fromFourBytes: data.subdata(in: 0..<4))
        self.rightAscension = Double(fromEightBytes: data.subdata(in: 4..<12))
        self.declination = Double(fromEightBytes: data.subdata(in: 12..<20))
        self.spectralType = SpectralType(fromData: data.subdata(in: 20..<22))
        self.magnitude = Double(Int(fromTwoBytesLittleEndian: data.subdata(in: 22..<24))) / 100.0
        
        if data.count >= 32 {
            self.rightAscensionProperMotion = Float(fromFourBytes: data.subdata(in: 24..<28))
            self.declinationProperMotion = Float(fromFourBytes: data.subdata(in: 28..<32))
        } else {
            self.rightAscensionProperMotion = nil
            self.declinationProperMotion = nil
        }
        
        if data.count >= 40 {
            self.radialVelocity = Double(fromEightBytes: data.subdata(in: 32..<40))
        } else {
            self.radialVelocity = nil
        }
    }
}

extension Int {
    init(fromTwoBytesLittleEndian data: Data) {
        self = Int(Int16(littleEndian: data.withUnsafeBytes({ $0.load(as: Int16.self) })))
    }
    
    init(fromFourBytesLittleEndian data: Data) {
        self = Int(Int32(littleEndian: data.withUnsafeBytes({ $0.load(as: Int32.self) })))
    }
}

extension Float {
    init(fromFourBytes data: Data) {
        self = data.withUnsafeBytes { Float(bitPattern: $0.load(as: UInt32.self)) }
    }
}

extension Double {
    init(fromEightBytes data: Data) {
        self = data.withUnsafeBytes { Double(bitPattern: $0.load(as: UInt64.self)) }
    }
}
