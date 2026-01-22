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
