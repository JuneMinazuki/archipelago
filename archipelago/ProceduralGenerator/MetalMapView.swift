import SwiftUI
import MetalKit

struct HexInstance {
    var centerPosition: simd_float2
    var color: simd_float4
    var distanceFromCenter: Float
}

struct MetalMapView: NSViewRepresentable {
    let tiles: [HexTile]
    let size: CGFloat
    let animationProgress: Double

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 30
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        let boundsSize = nsView.bounds.size.width > 0 ? nsView.bounds.size : CGSize(width: 800, height: 600)
        context.coordinator.updateTiles(tiles, pointSize: size, progress: animationProgress, viewSize: nsView.drawableSize, boundsSize: boundsSize)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalMapView
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        var instanceBuffer: MTLBuffer?
        var totalInstanceCount: Int = 0
        var currentInstanceCount: Int = 0
        
        private var lastTileHash: Int = 0

        init(_ parent: MetalMapView) {
            self.parent = parent
            super.init()
            if let device = MTLCreateSystemDefaultDevice() {
                self.device = device
                self.commandQueue = device.makeCommandQueue()
                setupPipeline(device: device)
            }
        }

        func setupPipeline(device: MTLDevice) {
            guard let library = device.makeDefaultLibrary(),
                  let vertexFunc = library.makeFunction(name: "hexagonVertex"),
                  let fragFunc = library.makeFunction(name: "hexagonFragment") else { return }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunc
            descriptor.fragmentFunction = fragFunc
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            } catch {
                print("Failed to create pipeline state: \(error)")
            }
        }

        func updateTiles(_ tiles: [HexTile], pointSize: CGFloat, progress: Double, viewSize: CGSize, boundsSize: CGSize) {
            guard let device = device, viewSize.width > 0, viewSize.height > 0 else { return }
            
            if tiles.isEmpty {
                instanceBuffer = nil
                totalInstanceCount = 0
                currentInstanceCount = 0
                lastTileHash = 0
                return
            }
            
            let tileHash = tiles.hashValue
            let scale = Float(viewSize.width / boundsSize.width)
            let hexRadius = Float(pointSize) * scale
            let halfW = Float(viewSize.width / 2.0)
            let floatH = Float(viewSize.height / 2.0)
            
            // Only rebuild buffer if tiles actually changed
            if instanceBuffer == nil || tileHash != lastTileHash {
                lastTileHash = tileHash
                var instances: [HexInstance] = []
                instances.reserveCapacity(tiles.count)
                
                for tile in tiles {
                    let q = Float(tile.q)
                    let r = Float(tile.r)
                    
                    let x = hexRadius * (sqrt(3.0) * q + sqrt(3.0) / 2.0 * r)
                    let y = hexRadius * (3.0 / 2.0 * r)
                    let distSq = x * x + y * y
                    
                    let centerX = x + halfW
                    let centerY = y + floatH
                    
                    let nsColor = tile.biomeColor
                    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                    NSColor(nsColor).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    let colorVector = simd_float4(Float(red), Float(green), Float(blue), Float(alpha))
                    
                    instances.append(HexInstance(centerPosition: simd_float2(centerX, centerY),
                                                 color: colorVector,
                                                 distanceFromCenter: distSq))
                }
                
                totalInstanceCount = instances.count
                if totalInstanceCount > 0 {
                    // Use resource options to optimize streaming/updates if needed
                    instanceBuffer = device.makeBuffer(bytes: instances, length: MemoryLayout<HexInstance>.stride * totalInstanceCount, options: .storageModeShared)
                }
            }
            
            currentInstanceCount = Int(progress * Double(tiles.count))
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let pipelineState = pipelineState,
                  let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let descriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable,
                  let instanceBuffer = instanceBuffer,
                  currentInstanceCount > 0 else { return }

            var viewSize = simd_float2(Float(view.drawableSize.width), Float(view.drawableSize.height))
            let boundsSize = view.bounds.size.width > 0 ? view.bounds.size : CGSize(width: 800, height: 600)
            let scale = Float(view.drawableSize.width / boundsSize.width)
            var hexRadius = Float(25) * scale // Match your hexagon radius size

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setVertexBuffer(instanceBuffer, offset: 0, index: 0)
            encoder?.setVertexBytes(&hexRadius, length: MemoryLayout<Float>.size, index: 1)
            encoder?.setVertexBytes(&viewSize, length: MemoryLayout<simd_float2>.size, index: 2)
            
            encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 18, instanceCount: currentInstanceCount)
            encoder?.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
