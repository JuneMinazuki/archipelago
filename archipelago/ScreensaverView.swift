import SwiftUI
import Combine

struct ScreensaverView: View {
    @State private var tiles: [HexTile] = []
    @State private var contentOpacity: Double = 1.0
    let generator = IslandGenerator()
    
    let timer = Timer.publish(every: 8.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let size: CGFloat = 20 // Hexagon radius size
                let width = geometry.size.width
                let height = geometry.size.height
                
                let qRadius = Int(ceil(width / (sqrt(3.0) * size))) + 2
                let rRadius = Int(ceil(height / (1.5 * size))) + 2
                let maxRadius = max(qRadius, rRadius)
                
                Canvas { context, canvasSize in
                    for tile in tiles {
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
                .onAppear {
                    generateAsync(radius: maxRadius)
                }
                .onChange(of: maxRadius) {
                    generateAsync(radius: maxRadius)
                }
                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 1.0)) {
                        contentOpacity = 0.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        let dynQR = Int(ceil(width / (sqrt(3.0) * size))) + 2
                        let dynRR = Int(ceil(height / (1.5 * size))) + 2
                        let dynamicRadius = max(dynQR, dynRR)
                        
                        generateAsync(radius: dynamicRadius) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                contentOpacity = 1.0
                            }
                        }
                    }
                }
            }
            .opacity(contentOpacity)
        }
    }
    
    private func generateAsync(radius: Int, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let newTiles = generator.generateGrid(radius: radius)
            DispatchQueue.main.async {
                self.tiles = newTiles
                completion?()
            }
        }
    }
}
