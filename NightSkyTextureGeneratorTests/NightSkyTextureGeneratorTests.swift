//
//  NightSkyTextureGeneratorTests.swift
//  NightSkyTextureGeneratorTests
//
//  Created by Jason Neel on 1/21/26.
//

import Testing
import Foundation
@testable import NightSkyTextureGenerator

struct NightSkyTextureGeneratorTests {
    var catalogue: StarCatalogue!
    
    init() throws {
        let bundle = Bundle.main
        let fileUrl = bundle.url(forResource: "BSC5", withExtension: "dms")!
        let data = try Data(contentsOf: fileUrl)
        
        self.catalogue = StarCatalogue(fromBinaryData: data)
    }
    
    @Test("All 9110 stars are loaded")
    func testAllStarsLoaded() throws {
        #expect(catalogue.stars.count == 9110)
        
        let firstStar = catalogue.stars.first!
        let lastStar = catalogue.stars.last!
        
        #expect(firstStar.catalogueNumber == 1)
        #expect(lastStar.catalogueNumber == 9110)
    }
    
    @Test("Coordinates are parsed")
    func testCoordinates() {
        let firstStar = catalogue.stars.first!
        let lastStar = catalogue.stars.last!
        
        #expect(abs(firstStar.rightAscension - (0.0 + 5.0 / 60.0 + 9.9 / 3600.0) * 15.0 * .pi / 180.0) < 0.001)
        #expect(abs(firstStar.declination - (45.0 + 13.0 / 60.0 + 45.0 / 3600.0) * .pi / 180.0) < 0.001)
        #expect(abs(lastStar.rightAscension - (0.0 + 5.0 / 60.0 + 6.2 / 3600.0) * 15.0 * .pi / 180.0) < 0.001)
        #expect(abs(lastStar.declination - (61.0 + 18.0 / 60.0 + 51.0 / 3600.0) * .pi / 180.0) < 0.001)
    }
    
    @Test("Magnitude and spectral types are parsed")
    func testMagnitudeAndType() {
        let firstStar = catalogue.stars.first!
        let lastStar = catalogue.stars.last!
        
        #expect(firstStar.magnitude == 670)
        #expect(lastStar.magnitude == 580)
        
        #expect(firstStar.spectralType == "A1")
        #expect(lastStar.spectralType == "B8")
    }
}
