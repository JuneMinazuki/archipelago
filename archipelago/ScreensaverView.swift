import SwiftUI
import Combine

struct RenderableTile {
    let q: Int
    let r: Int
    let biomeColor: Color
    let path: Path
}

struct ScreensaverView: View {
    @State private var renderableTiles: [RenderableTile] = []
    @State private var animationStartDate: Date? = nil
    @State private var contentOpacity: Double = 1.0
    @State private var animationProgress: Double = 0.0
    @State private var isHolding: Bool = false
    let generator = IslandGenerator()
    
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
                    
                    Canvas { context, canvasSize in
                        let countToDraw = Int(progress * Double(renderableTiles.count))
                        let visibleTiles = renderableTiles.prefix(countToDraw)
                        
                        for tile in visibleTiles {
                            context.fill(tile.path, with: .color(tile.biomeColor))
                            context.stroke(tile.path, with: .color(tile.biomeColor), lineWidth: 1.0)
                        }
                    }
                    .onChange(of: progress) { oldValue, newValue in
                        animationProgress = newValue
                        if newValue >= 1.0 && !isHolding {
                            triggerHoldPhase(radius: maxRadius, size: size, width: width, height: height)
                        }
                    }
                }
                .onAppear {
                    startCycle(radius: maxRadius, size: size, width: width, height: height)
                }
            }
            .opacity(contentOpacity)
        }
    }
    
    // Generates grid
    private func startCycle(radius: Int, size: CGFloat, width: CGFloat, height: CGFloat) {
        isHolding = false
        animationProgress = 0.0
        
        Task.detached(priority: .userInitiated) {
            let generator = IslandGenerator()
            let rawTiles = generator.generateGrid(radius: radius)
            
            let halfWidth = width / 2
            let halfHeight = height / 2
            
            let filteredTiles = rawTiles.filter { tile in
                let x = size * (sqrt(3.0) * CGFloat(tile.q) + sqrt(3.0) / 2.0 * CGFloat(tile.r))
                let y = size * (3.0 / 2.0 * CGFloat(tile.r))
                return abs(x) <= halfWidth + (size * 3) && abs(y) <= halfHeight + (size * 3)
            }
            
            let sortedTiles = filteredTiles.sorted { t1, t2 in
                let x1 = size * (sqrt(3.0) * CGFloat(t1.q) + sqrt(3.0) / 2.0 * CGFloat(t1.r))
                let y1 = size * (3.0 / 2.0 * CGFloat(t1.r))
                let x2 = size * (sqrt(3.0) * CGFloat(t2.q) + sqrt(3.0) / 2.0 * CGFloat(t2.r))
                let y2 = size * (3.0 / 2.0 * CGFloat(t2.r))
                
                return (x1 * x1 + y1 * y1) < (x2 * x2 + y2 * y2)
            }
            
            let finalRenderableTiles: [RenderableTile] = sortedTiles.map { tile in
                let x = size * (sqrt(3.0) * CGFloat(tile.q) + sqrt(3.0) / 2.0 * CGFloat(tile.r))
                let y = size * (3.0 / 2.0 * CGFloat(tile.r))
                
                let centerX = halfWidth + x
                let centerY = halfHeight + y
                
                var path = Path()
                for i in 0..<6 {
                    let angle = CGFloat(i) * .pi / 3.0 + .pi / 6.0
                    let hx = centerX + size * cos(angle)
                    let hy = centerY + size * sin(angle)
                    if i == 0 {
                        path.move(to: CGPoint(x: hx, y: hy))
                    } else {
                        path.addLine(to: CGPoint(x: hx, y: hy))
                    }
                }
                path.closeSubpath()
                
                return RenderableTile(
                    q: tile.q,
                    r: tile.r,
                    biomeColor: tile.biomeColor,
                    path: path
                )
            }
            
            await MainActor.run {
                self.renderableTiles = finalRenderableTiles
                self.contentOpacity = 1.0
                self.animationStartDate = Date()
            }
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
                self.renderableTiles = []
                
                let dynQR = Int(ceil(width / (sqrt(3.0) * size))) + 2
                let dynRR = Int(ceil(height / (1.5 * size))) + 2
                let dynamicRadius = max(dynQR, dynRR)
                
                startCycle(radius: dynamicRadius, size: size, width: width, height: height)
            }
        }
    }
}
