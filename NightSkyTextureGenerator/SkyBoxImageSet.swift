//
//  SkyBoxImageSet.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/21/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SkyBoxImageSet {
    let images: [CubeFace: CGImage]
    
    var tiffDocuments: [SkyBoxTiffDocument] {
        CubeFace.allCases.map {
            SkyBoxTiffDocument(image: images[$0]!, cubeFace: $0)
        }
    }
    
    var pngDocuments: [SkyBoxPngDocument] {
        CubeFace.allCases.map {
            SkyBoxPngDocument(image: images[$0]!, cubeFace: $0)
        }
    }
    
    init(
        withStarCatalogue starCatalogue: StarCatalogue,
        cubeFaceSize: Int,
        magnitudeCutoff: Double = 6.0
    ) {
        var images: [CubeFace: CGImage] = [:]
        var contexts: [CubeFace: CGContext] = [:]

        CubeFace.allCases.forEach {
            contexts[$0] = CGContext(
                data: nil,
                width: cubeFaceSize,
                height: cubeFaceSize,
                bitsPerComponent: 16,
                bytesPerRow: cubeFaceSize * 8,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        }
        
        starCatalogue.stars.forEach { star in
            let brightness = star.brightnessWithCutoff(cutoff: magnitudeCutoff)
            
            guard brightness > 0, let color = star.spectralType?.color else {
                return
            }
            
            let direction = star.direction
            let coordinate = direction.textureCoordinate
            let x = Int(coordinate.u * Double(cubeFaceSize))
            let y = Int((1.0 - coordinate.v) * Double(cubeFaceSize))
            let radius = max(1, Int(3.5 - star.magnitude * 0.5))
            
            contexts[coordinate.face]!.drawStar(x: x, y: y, radius: radius, brightness: brightness, color: color)
        }
        
        CubeFace.allCases.forEach {
            images[$0] = contexts[$0]!.makeImage()!
        }
        
        self.images = images
    }
}

extension CGContext {
    func drawStar(x: Int, y: Int, radius: Int, brightness: Double, color: CGColor) {
        for dy in -radius...radius {
            for dx in -radius...radius {
                let r2 = dx * dx + dy * dy
                let falloff = exp(-Double(r2) / Double(radius * radius))
                
                guard falloff > 0.01 else {
                    continue
                }
                
                let intensity = brightness * falloff
                
                setFillColor(CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components:[
                    color.components![0] * intensity,
                    color.components![1] * intensity,
                    color.components![2] * intensity,
                    1.0
                ])!)
                
                setFillColor(color)
                fill(CGRect(origin: CGPoint(x: x + dx, y: y + dy), size: CGSize(width: 1.0, height: 1.0)))
            }
        }
    }
}

struct TextureCoordinate {
    let face: CubeFace
    let u: Double
    let v: Double
}

struct CubeFace: Hashable, CaseIterable {
    let axis: Axis
    let sign: Sign
    
    static var allCases: [CubeFace] {
        Sign.allCases.flatMap { sign in
            Axis.allCases.map { axis in
                CubeFace(axis: axis, sign: sign)
            }
        }
    }
}

enum Axis: CaseIterable {
    case x
    case y
    case z
}

enum Sign: CaseIterable {
    case positive
    case negative
    
    init(of x: Double) {
        if x >= 0.0 {
            self = .positive
        } else {
            self = .negative
        }
    }
}

extension StarCatalogue.Star {
    var direction: SIMD3<Double> {
        SIMD3(cos(declination) * cos(rightAscension), sin(declination), cos(declination) * sin(rightAscension))
    }
    
    func brightnessWithCutoff(cutoff: Double) -> Double {
        let magnitude = Double(self.magnitude) / 100.0
        guard magnitude < cutoff else {
            return 0.0
        }
        
        return pow(10.0, -0.4 * magnitude)
    }
}

extension SIMD3<Double> {
    var textureCoordinate: TextureCoordinate {
        let x = self.x
        let y = self.y
        let z = self.z
        let ax = abs(x)
        let ay = abs(y)
        let az = abs(z)
        
        let face: CubeFace
        let sc: Double
        let tc: Double
        let ma: Double
        
        if ax >= ay && ax >= az {
            face = CubeFace(axis: .x, sign: Sign(of: x))
            ma = ax
            sc = x > 0.0 ? -z : z
            tc = y
        } else if ay >= ax && ay >= az {
            face = CubeFace(axis: .y, sign: Sign(of: y))
            ma = ay
            sc = x
            tc = y > 0.0 ? -z : z
        } else {
            face = CubeFace(axis: .z, sign: Sign(of: z))
            ma = az
            sc = z > 0.0 ? x : -x
            tc = y
        }

        return TextureCoordinate(face: face, u: 0.5 * (sc / ma + 1.0), v: 0.5 * (tc / ma + 1.0))
    }
}

extension StarCatalogue.Star.SpectralType {
    var temperature: Double {
        let classTemperature = starClass.temperature
        let coolerTemperature = starClass.nextCoolestClass.temperature
        
        let f = Double(refinement) / 10.0
        return classTemperature * (1.0 - f) + coolerTemperature * f
    }
    
    /// Approximate black body radiation color
    /// from https://tannerhelland.com/2012/09/18/convert-temperature-rgb-algorithm-code.html
    var color: CGColor {
        let t = temperature / 100.0
        
        let lr: CGFloat
        let lg: CGFloat
        let lb: CGFloat
        
        if t <= 66 {
            lr = 1.0
            lg = clamp(0.3900816 * log(t) - 0.6318414, 0.0, 1.0)
            lb = t <= 19.0 ? 0.0 : clamp(0.5432068 * log(t - 10.0) - 1.1962541, 0.0, 1.0)
        } else {
            lr = clamp(1.2929362 * pow(t - 60.0, -0.1332048), 0.0, 1.0)
            lg = clamp(1.1298909 * pow(t - 60.0, -0.0755148), 0.0, 1.0)
            lb = 1.0
        }
        
        return CGColor(red: linearToSRGB(lr), green: linearToSRGB(lg), blue: linearToSRGB(lb), alpha: 1.0)
    }
}

func linearToSRGB(_ x: Double) -> Double {
    x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055
}

func clamp(_ x: Double, _ minVal: Double, _ maxVal: Double) -> Double {
    return min(max(x, minVal), maxVal)
}

extension StarCatalogue.Star.SpectralType.StarClass {
    var temperature: Double {
        switch self {
        case .o:
            return 40_000.0
        case .b:
            return 20_000.0
        case .a:
            return 8_500.0
        case .f:
            return 6_500.0
        case .g:
            return 5_500.0
        case .k:
            return 4_500.0
        case .m:
            return 3_200.0
        }
    }
    
    var nextCoolestClass: Self {
        switch self {
        case .o:
            return .b
        case .b:
            return .a
        case .a:
            return .f
        case .f:
            return .g
        case .g:
            return .k
        case .k, .m:
            return .m
        }
    }
}

struct SkyBoxTiffDocument: FileDocument {
    static var readableContentTypes: [UTType] { [ .tiff ] }
    
    var image: CGImage
    var cubeFace: CubeFace
    
    init(image: CGImage, cubeFace: CubeFace) {
        self.image = image
        self.cubeFace = cubeFace
    }
    
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.featureUnsupported)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.tiff.identifier as CFString,
            1,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        
        let properties = [
            kCGImagePropertyTIFFCompression: NSNumber(value: 5)
        ] as CFDictionary
        
        
        CGImageDestinationAddImage(destination, image, properties)
        
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let fileWrapper = FileWrapper(regularFileWithContents: data as Data)
        fileWrapper.preferredFilename = "skybox-\(cubeFace.fileSuffix)"
        
        return fileWrapper
    }
}

struct SkyBoxPngDocument: FileDocument {
    static var readableContentTypes: [UTType] { [ .png ] }
    
    var image: CGImage
    var cubeFace: CubeFace
    
    init(image: CGImage, cubeFace: CubeFace) {
        self.image = image
        self.cubeFace = cubeFace
    }
    
    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.featureUnsupported)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let fileWrapper = FileWrapper(regularFileWithContents: data as Data)
        fileWrapper.preferredFilename = "skybox-\(cubeFace.fileSuffix)"
        
        return fileWrapper
    }
}

extension CubeFace {
    var fileSuffix: String {
        let sign = sign == .positive ? "pos" : "neg"
        let axis: String
        
        switch self.axis {
        case .x: axis = "X"
        case .y: axis = "Y"
        case .z: axis = "Z"
        }
        
        return sign + axis
    }
}
