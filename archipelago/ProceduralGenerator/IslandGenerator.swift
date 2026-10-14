import Foundation
import SwiftUI
import GameplayKit

struct HexCoord: Hashable, Sendable {
    let q: Int
    let r: Int
}

struct HexTile: Identifiable, Sendable {
    var id: String { "\(q),\(r)" }
    let q: Int
    let r: Int
    var elevation: Double
    
    var biomeColor: Color {
        if elevation < 0.25 { return Color(red: 0.08, green: 0.25, blue: 0.55) }    // Deep Water
        if elevation < 0.35 { return Color(red: 0.15, green: 0.45, blue: 0.75) }    // Shallow Water
        if elevation < 0.41 { return Color(red: 0.82, green: 0.76, blue: 0.55) }    // Sand
        if elevation < 0.55 { return Color(red: 0.22, green: 0.55, blue: 0.28) }    // Grass
        if elevation < 0.68 { return Color(red: 0.12, green: 0.38, blue: 0.20) }    // Forest
        if elevation < 0.85 { return Color(red: 0.40, green: 0.40, blue: 0.42) }    // Mountain Rock
        return Color(red: 0.95, green: 0.95, blue: 0.98)                            // Snow Peak
    }
}

class IslandGenerator {
    
    // Axial directions for the 6 neighbors
    private let hexDirections: [HexCoord] = [
        HexCoord(q: 1, r: 0), HexCoord(q: -1, r: 0),
        HexCoord(q: 0, r: 1), HexCoord(q: 0, r: -1),
        HexCoord(q: 1, r: -1), HexCoord(q: -1, r: 1)
    ]

    func generateGrid(radius: Int) -> [HexTile] {
        let noiseSource = GKPerlinNoiseSource(frequency: 3.5, octaveCount: 4, persistence: 0.5, lacunarity: 2.0, seed: Int32.random(in: 1...10000))
        let noiseMap = GKNoise(noiseSource)
        
        let sampleDim = Int32(radius * 2)
        let map = GKNoiseMap(
            noiseMap,
            size: vector_double2(2.0, 2.0),
            origin: vector_double2(-1.0, -1.0),
            sampleCount: vector_int2(sampleDim, sampleDim),
            seamless: false
        )

        let estimatedCapacity = (radius * 2 + 1) * (radius * 2 + 1)
        var tileDict: [HexCoord: Double] = [:]
        tileDict.reserveCapacity(estimatedCapacity)
        
        var coords: [HexCoord] = []
        coords.reserveCapacity(estimatedCapacity)
        
        let doubleRadius = Double(radius)
        for q in -radius...radius {
            let r1 = max(-radius, -q - radius)
            let r2 = min(radius, -q + radius)
            for r in r1...r2 {
                let coord = HexCoord(q: q, r: r)
                coords.append(coord)
                
                let sampleX = Int32(Float(q + radius) / Float(radius * 2) * Float(sampleDim))
                let sampleY = Int32(Float(r + radius) / Float(radius * 2) * Float(sampleDim))
                
                let sampleCoord = vector_int2(
                    min(max(sampleX, 0), sampleDim - 1),
                    min(max(sampleY, 0), sampleDim - 1)
                )
                
                let rawNoise = Double(map.value(at: sampleCoord))
                let normalizedNoise = (rawNoise + 1.0) / 2.0
                
                let distanceFromCenter = sqrt(Double(q * q + q * r + r * r)) / doubleRadius
                let angle = atan2(Double(r), Double(q))
                let noiseDistortion = sin(angle * 4.0) * 0.07 + cos(angle * 6.0) * 0.04
                let adjustedDistance = max(0.0, distanceFromCenter + noiseDistortion)
                
                let falloff = max(0.0, 1.0 - pow(adjustedDistance, 1.6))
                tileDict[coord] = max(0.0, min(1.0, normalizedNoise * falloff))
            }
        }
        
        var neighborCache: [HexCoord: [HexCoord]] = [:]
        neighborCache.reserveCapacity(coords.count)
        for coord in coords {
            var validNeighbors: [HexCoord] = []
            validNeighbors.reserveCapacity(6)
            for dir in hexDirections {
                let neighborCoord = HexCoord(q: coord.q + dir.q, r: coord.r + dir.r)
                if tileDict[neighborCoord] != nil {
                    validNeighbors.append(neighborCoord)
                }
            }
            neighborCache[coord] = validNeighbors
        }
        
        for _ in 0..<2 {
            var updatedDict = tileDict
            for coord in coords {
                let elevation = tileDict[coord]!
                let neighbors = neighborCache[coord]!
                
                var neighborSum = elevation * 2.0
                var weightTotal = 2.0
                
                for neighborCoord in neighbors {
                    if let neighborElevation = tileDict[neighborCoord] {
                        neighborSum += neighborElevation
                        weightTotal += 1.0
                    }
                }
                
                updatedDict[coord] = neighborSum / weightTotal
            }
            tileDict = updatedDict
        }
        
        for _ in 0..<2 {
            var updatedDict = tileDict
            
            for coord in coords {
                let elevation = tileDict[coord]!
                let neighbors = neighborCache[coord]!
                
                let isSnow = elevation >= 0.85
                let isGrassOrForest = (elevation >= 0.41 && elevation < 0.68)
                let isSand = (elevation >= 0.35 && elevation < 0.41)
                
                var touchesWater = false
                var touchesNonMountain = false
                
                for neighborCoord in neighbors {
                    if let nElev = tileDict[neighborCoord] {
                        if nElev < 0.35 { touchesWater = true }
                        if nElev < 0.68 { touchesNonMountain = true }
                        
                        if isSand && nElev < 0.25 {
                            updatedDict[neighborCoord] = 0.30
                        }
                    }
                }
                
                // Snow must be surrounded by mountian
                if isSnow && touchesNonMountain {
                    updatedDict[coord] = 0.78 // Convert to mountian
                }
                
                // Grass or forest cannot touch water
                if isGrassOrForest && touchesWater {
                    updatedDict[coord] = 0.38 // Convert to sand
                }
            }
            tileDict = updatedDict
        }
        
        for _ in 0..<2 {
            var updatedDict = tileDict
            
            for coord in coords {
                let elevation = tileDict[coord]!
                let neighbors = neighborCache[coord]!
                
                var neighborElevSum = 0.0
                var mountainNeighborCount = 0
                var deepWaterNeighborCount = 0
                var landNeighborCount = 0
                var forestNeighborCount = 0
                
                for neighborCoord in neighbors {
                    let nElev = tileDict[neighborCoord]!
                    neighborElevSum += nElev
                    if nElev >= 0.68 { mountainNeighborCount += 1 }
                    if nElev < 0.25 { deepWaterNeighborCount += 1 }
                    if nElev >= 0.35 { landNeighborCount += 1 }
                    if nElev >= 0.55 && nElev < 0.68 { forestNeighborCount += 1 }
                }
                
                let neighborCount = Double(neighbors.count)
                
                // Remove isolated tile
                let isGrass = elevation >= 0.41 && elevation < 0.55
                if isGrass && forestNeighborCount >= 2 {
                    updatedDict[coord] = 0.60
                }
                
                let isForest = elevation >= 0.55 && elevation < 0.68
                if isForest && forestNeighborCount == 0 && mountainNeighborCount == 0 {
                    updatedDict[coord] = 0.50
                }
                
                if elevation < 0.25 && deepWaterNeighborCount == 0 && landNeighborCount >= 4 {
                    updatedDict[coord] = 0.38 // Convert to Sand
                }
                
                // Checks mountain and snow peaks to ensure they are part of a cluster
                let isPeak = elevation >= 0.85
                if isPeak && mountainNeighborCount < 2 {
                    updatedDict[coord] = 0.78 // Lower to mountain rock
                }
                
                // Smooths out extreme outlier pixels against their surrounding neighborhood
                if neighborCount > 0 {
                    let avgNeighbor = neighborElevSum / neighborCount
                    if abs(elevation - avgNeighbor) > 0.35 && neighbors.count >= 5 {
                        let current = updatedDict[coord] ?? elevation
                        updatedDict[coord] = current * 0.5 + avgNeighbor * 0.5
                    }
                }
                
                // Remove isolated Shallow Water Cleanup
                let isShallowWater = elevation >= 0.25 && elevation < 0.35
                if isShallowWater && deepWaterNeighborCount == 0 && landNeighborCount >= 5 {
                    updatedDict[coord] = 0.38 // Convert isolated shallow water to sand
                }
            }
            tileDict = updatedDict
        }
        
        return tileDict.map { HexTile(q: $0.key.q, r: $0.key.r, elevation: $0.value) }
    }
}
