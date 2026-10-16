import SwiftUI
import Combine

struct ScreensaverView: View {
    @State private var sortedTiles: [HexTile] = []
    @State private var nextTiles: [HexTile] = []
    @State private var animationStartDate: Date? = nil
    @State private var contentOpacity: Double = 1.0
    @State private var isHolding: Bool = false
    
    // Animation phases (in seconds)
    let animationDuration: Double = 10.0
    let holdDuration: Double = 15.0
    let fadeDuration: Double = 5.0

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let size: CGFloat = 25 // Hexagon radius size
                let width = geometry.size.width
                let height = geometry.size.height
                
                let qRadius = Int(ceil(width / (sqrt(3.0) * size))) + 2
                let rRadius = Int(ceil(height / (1.5 * size))) + 2
                let maxRadius = max(qRadius, rRadius)
                
                TimelineView(.animation) { timeline in
                    let progress: Double = {
                        guard let startDate = animationStartDate else { return 0.0 }
                        let elapsed = timeline.date.timeIntervalSince(startDate)
                        return min(max(elapsed / animationDuration, 0.0), 1.0)
                    }()
                    
                    MetalMapView(
                        tiles: sortedTiles,
                        size: size,
                        animationProgress: progress
                    )
                    .opacity(contentOpacity)
                    .onChange(of: progress) { _, newValue in
                        if newValue >= 1.0 && !isHolding {
                            triggerHoldPhase(radius: maxRadius, size: size, width: width, height: height)
                        }
                    }
                }
                .onAppear {
                    generateInitialGrid(radius: maxRadius, size: size, width: width, height: height)
                }
            }
        }
    }
    
    private func generateInitialGrid(radius: Int, size: CGFloat, width: CGFloat, height: CGFloat) {
        Task.detached(priority: .userInitiated) {
            let tiles = computeGrid(radius: radius, size: size, width: width, height: height)
            await MainActor.run {
                self.animationStartDate = nil
                self.sortedTiles = tiles
                self.contentOpacity = 1.0
                self.animationStartDate = Date()
                
                prepareNextGrid(radius: radius, size: size, width: width, height: height)
            }
        }
    }
    
    private func prepareNextGrid(radius: Int, size: CGFloat, width: CGFloat, height: CGFloat) {
        Task.detached(priority: .utility) {
            let tiles = computeGrid(radius: radius, size: size, width: width, height: height)
            await MainActor.run {
                self.nextTiles = tiles
            }
        }
    }
    
    nonisolated private func computeGrid(radius: Int, size: CGFloat, width: CGFloat, height: CGFloat) -> [HexTile] {
        let generator = IslandGenerator()
        let rawTiles = generator.generateGrid(radius: radius)
        
        let halfWidth = width / 2
        let halfHeight = height / 2
        
        let filteredTiles = rawTiles.filter { tile in
            let x = size * (sqrt(3.0) * CGFloat(tile.q) + sqrt(3.0) / 2.0 * CGFloat(tile.r))
            let y = size * (3.0 / 2.0 * CGFloat(tile.r))
            return abs(x) <= halfWidth + (size * 3) && abs(y) <= halfHeight + (size * 3)
        }
        
        return filteredTiles.sorted { t1, t2 in
            let x1 = size * (sqrt(3.0) * CGFloat(t1.q) + sqrt(3.0) / 2.0 * CGFloat(t1.r))
            let y1 = size * (3.0 / 2.0 * CGFloat(t1.r))
            let x2 = size * (sqrt(3.0) * CGFloat(t2.q) + sqrt(3.0) / 2.0 * CGFloat(t2.r))
            let y2 = size * (3.0 / 2.0 * CGFloat(t2.r))
            
            return (x1 * x1 + y1 * y1) < (x2 * x2 + y2 * y2)
        }
    }
    
    private func triggerHoldPhase(radius: Int, size: CGFloat, width: CGFloat, height: CGFloat) {
        guard !isHolding else { return }
        isHolding = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
            withAnimation(.easeInOut(duration: fadeDuration)) {
                contentOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                if !self.nextTiles.isEmpty {
                    self.animationStartDate = nil
                    self.sortedTiles = self.nextTiles
                    self.nextTiles = []
                }
                
                self.contentOpacity = 1.0
                self.animationStartDate = Date()
                self.isHolding = false
                
                let dynQR = Int(ceil(width / (sqrt(3.0) * size))) + 2
                let dynRR = Int(ceil(height / (1.5 * size))) + 2
                let dynamicRadius = max(dynQR, dynRR)
                prepareNextGrid(radius: dynamicRadius, size: size, width: width, height: height)
            }
        }
    }
}
