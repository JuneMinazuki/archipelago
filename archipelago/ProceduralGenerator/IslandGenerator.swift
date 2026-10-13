import Foundation
import SwiftUI
import GameplayKit

struct HexTile: Identifiable {
    let id = UUID()
    let q: Int
    let r: Int
    let elevation: Double
    var biomeColor: Color {
        if elevation < 0.25 { return Color(red: 0.1, green: 0.3, blue: 0.6) }       // Deep Water
        if elevation < 0.35 { return Color(red: 0.2, green: 0.5, blue: 0.8) }       // Shallow Water
        if elevation < 0.40 { return Color(red: 0.85, green: 0.80, blue: 0.60) }    // Beach / Sand
        if elevation < 0.65 { return Color(red: 0.25, green: 0.60, blue: 0.30) }    // Grass / Forest
        if elevation < 0.82 { return Color(red: 0.50, green: 0.50, blue: 0.50) }    // Mountain Rock
        return Color.white                                                          // Snow Peak
    }
}

class IslandGenerator {
    func generateGrid(radius: Int) -> [HexTile] {
        let noiseSource = GKPerlinNoiseSource(frequency: 4.0, octaveCount: 4, persistence: 0.5, lacunarity: 2.0, seed: Int32.random(in: 1...10000))
        let noiseMap = GKNoise(noiseSource)
        
        var tiles: [HexTile] = []
        let sampleDim = Int32(radius * 2)
        
        let map = GKNoiseMap(
            noiseMap,
            size: vector_double2(2.0, 2.0),
            origin: vector_double2(-1.0, -1.0),
            sampleCount: vector_int2(sampleDim, sampleDim),
            seamless: false
        )

        for q in -radius...radius {
            let r1 = max(-radius, -q - radius)
            let r2 = min(radius, -q + radius)
            for r in r1...r2 {
                let sampleX = Int32(Float(q + radius) / Float(radius * 2) * Float(sampleDim))
                let sampleY = Int32(Float(r + radius) / Float(radius * 2) * Float(sampleDim))
                
                let sampleCoord = vector_int2(
                    min(max(sampleX, 0), sampleDim - 1),
                    min(max(sampleY, 0), sampleDim - 1)
                )
                
                let rawNoise = Double(map.value(at: sampleCoord))
                let normalizedNoise = (rawNoise + 1.0) / 2.0
                
                let distanceFromCenter = sqrt(Double(q * q + q * r + r * r)) / Double(radius)
                let falloff = max(0.0, 1.0 - pow(distanceFromCenter, 1.8))
                
                let finalElevation = max(0.0, min(1.0, normalizedNoise * falloff))
                
                tiles.append(HexTile(q: q, r: r, elevation: finalElevation))
            }
        }
        return tiles
    }
}
