//
//  ContentView.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    var starData: StarCatalogue
    @State var magnitudeCutoff: Double = 6.0
    @State var cubeFaceSizePower: Double = 10
    
    var body: some View {
        VStack {
            cubeGrid
                .padding()
            
            VStack {
                HStack {
                    Text("Magnitude cutoff: ")
                    Slider(value: $magnitudeCutoff, in: 0.0...0.10, step: 0.005)
                    Text(String(format: "%.2f", magnitudeCutoff))
                }
                
                HStack {
                    Text("Texture size: ")
                    Slider(value: $cubeFaceSizePower, in: 8...15, step: 1.0)
                    Text("\(Int(pow(2.0, cubeFaceSizePower)))")
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
                imageSet.images[CubeFace(axis: .y, sign: .positive)]!.resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
            }
            
            HStack(spacing: 0.0) {
                imageSet.images[CubeFace(axis: .x, sign: .negative)]!.resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                imageSet.images[CubeFace(axis: .z, sign: .negative)]!.resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                imageSet.images[CubeFace(axis: .x, sign: .positive)]!.resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                imageSet.images[CubeFace(axis: .z, sign: .positive)]!.resizable()
                    .aspectRatio(1.0, contentMode: .fit)
            }
            
            HStack(spacing: 0.0) {
                Rectangle().aspectRatio(1.0, contentMode: .fit).opacity(0.0)
                imageSet.images[CubeFace(axis: .y, sign: .negative)]!.resizable()
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
