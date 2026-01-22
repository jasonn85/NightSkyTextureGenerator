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
