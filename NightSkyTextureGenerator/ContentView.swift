//
//  ContentView.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/21/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        let bundle = Bundle.main
        let fileUrl = bundle.url(forResource: "BSC5", withExtension: "dms")!
        let data = try! Data(contentsOf: fileUrl)
        let starData = StarCatalogue(fromBinaryData: data)
        
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
