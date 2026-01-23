//
//  SkyBoxImageSetExporting.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/22/26.
//

import SwiftUI
import UniformTypeIdentifiers

extension SkyBoxImageSet {
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
    
    var flatTiffDocument: SkyBoxFlatTiffDocument {
        SkyBoxFlatTiffDocument(image: flattenedImages)
    }
    
    var flatPngDocument: SkyBoxFlatPngDocument {
        SkyBoxFlatPngDocument(image: flattenedImages)
    }
    
    var flattenedImages: CGImage {
        let order: [CubeFace] = [
            CubeFace(axis: .x, sign: .positive),
            CubeFace(axis: .x, sign: .negative),
            CubeFace(axis: .y, sign: .positive),
            CubeFace(axis: .y, sign: .negative),
            CubeFace(axis: .z, sign: .positive),
            CubeFace(axis: .z, sign: .negative),
        ]
        
        let images = order.map { self.images[$0]! }
        
        let singleWidth = images.first!.width
        let totalWidth = singleWidth * 6
        let height = images.first!.height
        
        let context = CGContext(data: nil, width: totalWidth, height: height, bitsPerComponent: 8, bytesPerRow: totalWidth * 4, space: CGColorSpace(name: CGColorSpace.sRGB), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))!
        
        for (i, image) in images.enumerated() {
            let x = CGFloat(i * singleWidth)
            context.draw(image, in: CGRect(x: x, y: 0, width: CGFloat(singleWidth), height: CGFloat(height)))
        }
        
        return context.makeImage()!
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

struct SkyBoxFlatTiffDocument: FileDocument {
    static var readableContentTypes: [UTType] { [ .tiff ] }
    
    var image: CGImage
    
    init(image: CGImage) {
        self.image = image
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

        return FileWrapper(regularFileWithContents: data as Data)
    }
}

struct SkyBoxFlatPngDocument: FileDocument {
    static var readableContentTypes: [UTType] { [ .png ] }
    
    var image: CGImage
    
    init(image: CGImage) {
        self.image = image
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

        return FileWrapper(regularFileWithContents: data as Data)
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
