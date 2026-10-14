import Foundation
import SwiftUI
import GameplayKit

struct HexTile: Identifiable {
    let id = UUID()
    let q: Int
    let r: Int
    var elevation: Double
    
    var biomeColor: Color {
        if elevation < 0.25 { return Color(red: 0.1, green: 0.3, blue: 0.6) }       // Deep Water
        if elevation < 0.35 { return Color(red: 0.2, green: 0.5, blue: 0.8) }       // Shallow Water
        if elevation < 0.40 { return Color(red: 0.85, green: 0.80, blue: 0.60) }    // Sand
        if elevation < 0.65 { return Color(red: 0.25, green: 0.60, blue: 0.30) }    // Grass
        if elevation < 0.82 { return Color(red: 0.50, green: 0.50, blue: 0.50) }    // Mountain Rock
        return Color.white                                                          // Snow Peak
    }
}

class IslandGenerator {
    
    // Axial directions for the 6 neighbors
    private let hexDirections = [
        (q: 1, r: 0), (q: -1, r: 0),
        (q: 0, r: 1), (q: 0, r: -1),
        (q: 1, r: -1), (q: -1, r: 1)
    ]

    func generateGrid(radius: Int) -> [HexTile] {
        let noiseSource = GKPerlinNoiseSource(frequency: 4.0, octaveCount: 4, persistence: 0.5, lacunarity: 2.0, seed: Int32.random(in: 1...10000))
        let noiseMap = GKNoise(noiseSource)
        
        let sampleDim = Int32(radius * 2)
        let map = GKNoiseMap(
            noiseMap,
            size: vector_double2(2.0, 2.0),
            origin: vector_double2(-1.0, -1.0),
            sampleCount: vector_int2(sampleDim, sampleDim),
            seamless: false
        )

        var tileDict: [String: Double] = [:]
        
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
                tileDict["\(q),\(r)"] = finalElevation
            }
        }
        
        for _ in 0..<2 {
            var updatedDict = tileDict
            for (key, elevation) in tileDict {
                let coords = key.split(separator: ",").compactMap { Int($0) }
                guard coords.count == 2 else { continue }
                let q = coords[0], r = coords[1]
                
                var neighborSum = elevation * 2.0
                var weightTotal = 2.0
                
                for dir in hexDirections {
                    let neighborKey = "\(q + dir.q),\(r + dir.r)"
                    if let neighborElevation = tileDict[neighborKey] {
                        neighborSum += neighborElevation
                        weightTotal += 1.0
                    }
                }
                
                updatedDict[key] = neighborSum / weightTotal
            }
            tileDict = updatedDict
        }
        
        var tiles: [HexTile] = []
        for (key, elevation) in tileDict {
            let coords = key.split(separator: ",").compactMap { Int($0) }
            if coords.count == 2 {
                tiles.append(HexTile(q: coords[0], r: coords[1], elevation: elevation))
            }
        }
        
        return tiles
    }
}
