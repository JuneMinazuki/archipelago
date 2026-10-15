import SwiftUI
import Combine

struct ScreensaverView: View {
    @State private var tiles: [HexTile] = []
    @State private var animationStartDate: Date? = nil
    @State private var contentOpacity: Double = 0.0
    @State private var animationProgress: Double = 0.0
    @State private var isHolding: Bool = false
    let generator = IslandGenerator()
    
    // Animation phases (in seconds)
    let animationDuration: Double = 35.0
    let holdDuration: Double = 5.0
    let fadeDuration: Double = 1.0

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
                        let countToDraw = Int(progress * Double(tiles.count))
                        let visibleTiles = tiles.prefix(countToDraw)
                        
                        for tile in visibleTiles {
                            let x = size * (sqrt(3.0) * CGFloat(tile.q) + sqrt(3.0) / 2.0 * CGFloat(tile.r))
                            let y = size * (3.0 / 2.0 * CGFloat(tile.r))
                            
                            let centerX = canvasSize.width / 2 + x
                            let centerY = canvasSize.height / 2 + y
                            
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
                            
                            context.fill(path, with: .color(tile.biomeColor))
                            context.stroke(path, with: .color(tile.biomeColor), lineWidth: 1.0)
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
    
    // Generates grid and fades in
    private func startCycle(radius: Int, size: CGFloat, width: CGFloat, height: CGFloat) {
        isHolding = false
        animationProgress = 0.0
        DispatchQueue.global(qos: .userInitiated).async { [generator] in
            let rawTiles = generator.generateGrid(radius: radius)
            
            let halfWidth = width / 2
            let halfHeight = height / 2
            
            let sortedTiles = rawTiles.sorted { t1, t2 in
                func pixelPos(_ tile: HexTile) -> (x: CGFloat, y: CGFloat) {
                    let x = size * (sqrt(3.0) * CGFloat(tile.q) + sqrt(3.0) / 2.0 * CGFloat(tile.r))
                    let y = size * (3.0 / 2.0 * CGFloat(tile.r))
                    return (x, y)
                }
                
                let pos1 = pixelPos(t1)
                let pos2 = pixelPos(t2)
                
                let isVisible1 = abs(pos1.x) <= halfWidth + size && abs(pos1.y) <= halfHeight + size
                let isVisible2 = abs(pos2.x) <= halfWidth + size && abs(pos2.y) <= halfHeight + size
                
                if isVisible1 != isVisible2 {
                    return isVisible1
                }
                
                let d1 = pos1.x * pos1.x + pos1.y * pos1.y
                let d2 = pos2.x * pos2.x + pos2.y * pos2.y
                return d1 < d2
            }
            
            DispatchQueue.main.async {
                self.tiles = sortedTiles
                self.animationStartDate = nil
                
                withAnimation(.easeInOut(duration: fadeDuration)) {
                    contentOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                    self.animationStartDate = Date()
                }
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
                let dynQR = Int(ceil(width / (sqrt(3.0) * size))) + 2
                let dynRR = Int(ceil(height / (1.5 * size))) + 2
                let dynamicRadius = max(dynQR, dynRR)
                
                startCycle(radius: dynamicRadius, size: size, width: width, height: height)
            }
        }
    }
}
