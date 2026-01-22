//
//  ContentView.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/21/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var starData: StarCatalogue
    @State private var magnitudeCutoff: Double = 0.06
    @State private var cubeFaceSizePower: Double = 10
    
    private let fileTypeOptions: [UTType] = [.tiff, .png]
    @State private var exportFileType: UTType = .tiff
    
    @State private var isExporting = false
    @State private var imagesToExport: SkyBoxImageSet? = nil
        
    var body: some View {
        VStack {
            cubeGrid
                .padding()
            
            VStack {
                HStack {
                    Text("Magnitude cutoff: ")
                    Slider(value: $magnitudeCutoff, in: 0.0...0.10, step: 0.0005)
                    Text(String(format: "%.4f", magnitudeCutoff))
                }
                
                HStack {
                    Text("Texture size: ")
                    Slider(value: $cubeFaceSizePower, in: 8...15, step: 1.0)
                    Text("\(Int(pow(2.0, cubeFaceSizePower)))")
                }
                .padding()
                                
                HStack {
                    Picker("File type", selection: $exportFileType) {
                        ForEach(fileTypeOptions, id: \.self) {
                            switch $0 {
                            case .tiff: Text("TIFF")
                            case .png: Text("PNG")
                            default: EmptyView()
                            }
                        }
                    }
                    
                    Spacer().frame(width: 30)
                    
                    switch exportFileType {
                    case .tiff:
                        Button("Export") {
                            imagesToExport = SkyBoxImageSet(withStarCatalogue: starData, cubeFaceSize: Int(pow(2.0, cubeFaceSizePower)), magnitudeCutoff: magnitudeCutoff)
                            
                            isExporting = true
                        }
                        .fileExporter(isPresented: $isExporting, documents: imagesToExport?.tiffDocuments ?? [], contentType: .tiff) { result in
                            isExporting = false
                        }
                        
                    case .png:
                        Button("Export") {
                            imagesToExport = SkyBoxImageSet(withStarCatalogue: starData, cubeFaceSize: Int(pow(2.0, cubeFaceSizePower)), magnitudeCutoff: magnitudeCutoff)
                            
                            isExporting = true
                        }
                        .fileExporter(isPresented: $isExporting, documents: imagesToExport?.pngDocuments ?? [], contentType: .png) { result in
                            isExporting = false
                        }
                        
                    default:
                        EmptyView()
                    }
                }
            }
            .frame(maxWidth: 400.0)
            .padding()
        }
        .padding()
    }
    
    @ViewBuilder
    var cubeGrid: some View {
        let imageSet = SkyBoxImageSet(withStarCatalogue: starData, cubeFaceSize: Int(pow(2.0, cubeFaceSizePower)), magnitudeCutoff: magnitudeCutoff)

        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
                Image(decorative: imageSet.images[CubeFace(axis: .y, sign: .positive)]!, scale: 1.0).resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
            }
            
            HStack(spacing: 0.0) {
                Image(decorative: imageSet.images[CubeFace(axis: .x, sign: .negative)]!, scale: 1.0).resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                Image(decorative: imageSet.images[CubeFace(axis: .z, sign: .negative)]!, scale: 1.0).resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                Image(decorative: imageSet.images[CubeFace(axis: .x, sign: .positive)]!, scale: 1.0).resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                Image(decorative: imageSet.images[CubeFace(axis: .z, sign: .positive)]!, scale: 1.0).resizable()
                    .aspectRatio(1.0, contentMode: .fit)
            }
            
            HStack(spacing: 0.0) {
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
                Image(decorative:imageSet.images[CubeFace(axis: .y, sign: .negative)]!, scale: 1.0).resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
            }
        }
    }
}

#Preview {
    let bundle = Bundle.main
    let fileUrl = bundle.url(forResource: "BSC5", withExtension: "dms")!
    let data = try! Data(contentsOf: fileUrl)
    let starData = StarCatalogue(fromBinaryData: data)
    
    ContentView(starData: starData)
}
