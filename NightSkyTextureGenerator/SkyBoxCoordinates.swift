//
//  SkyBoxCoordinates.swift
//  NightSkyTextureGenerator
//
//  Created by Jason Neel on 1/22/26.
//

import Foundation

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
