import SwiftUI
import Combine

struct ScreensaverView: View {
    @State private var tiles: [HexTile] = []
    let generator = IslandGenerator()
    
    let timer = Timer.publish(every: 8.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let size: CGFloat = 14 // Hexagon radius size
                let width = geometry.size.width
                let height = geometry.size.height
                
                ZStack {
                    ForEach(tiles) { tile in
                        let x = size * (sqrt(3.0) * CGFloat(tile.q) + sqrt(3.0) / 2.0 * CGFloat(tile.r))
                        let y = size * (3.0 / 2.0 * CGFloat(tile.r))
                        
                        HexagonShape()
                            .fill(tile.biomeColor)
                            .frame(width: size * 2, height: size * 2)
                            .position(x: width / 2 + x, y: height / 2 + y)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
            }
        }
        .onAppear {
            tiles = generator.generateGrid(radius: 18)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                tiles = generator.generateGrid(radius: 18)
            }
        }
    }
}
