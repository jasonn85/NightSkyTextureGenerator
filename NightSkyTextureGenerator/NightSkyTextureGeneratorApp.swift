//
//  NightSkyTextureGeneratorApp.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/21/26.
//

import SwiftUI

@main
struct NightSkyTextureGeneratorApp: App {
    var body: some Scene {
        let bundle = Bundle.main
        let fileUrl = bundle.url(forResource: "BSC5", withExtension: "dms")!
        let data = try! Data(contentsOf: fileUrl)
        let starData = StarCatalogue(fromBinaryData: data)
        
        WindowGroup {
            ContentView(starData: starData)
        }
    }
}
