import CNA
import Foundation

class HelloGame: Game {
    private var graphics: GraphicsDeviceManager!
    private var spriteBatch: SpriteBatch?
    private var logo: Texture2D?
    private var solid: Texture2D?
    private var cubeEffect: BasicEffect?
    
    private let smokeTest: Bool
    private var drawnFrames: UInt32 = 0
    private var animationSeconds: Float = 0
    private var rendererBannerSeconds: Float = 5.0
    
    private var velocity = Vector2(104, 74)
    private var position = Vector2.zero
    private var supports3D = false
    private let rendererName = "CNA (Swift)"

    init(smokeTest: Bool) {
        self.smokeTest = smokeTest
        self.graphics = GraphicsDeviceManager(game: self)
    }

    func Initialize() {
        supports3D = graphics.GraphicsDevice.SupportsCapability(.threeD)
        
        let viewport = graphics.GraphicsDevice.Viewport
        position = Vector2(Float(viewport.Width) / 2, Float(viewport.Height) / 2)
        
        print("\(rendererName): renderer initialized")
    }

    func LoadContent() {
        let device = graphics.GraphicsDevice
        spriteBatch = SpriteBatch(device: device)
        
        // Mock content loading
        logo = Texture2D()
        solid = Texture2D()
        
        if supports3D {
            cubeEffect = BasicEffect(device: device)
            cubeEffect?.TextureEnabled = true
            cubeEffect?.Texture = logo
        }
    }

    func Update(gameTime: GameTime) {
        let dt = Float(gameTime.elapsed)
        animationSeconds += dt
        
        if Keyboard.GetState().IsKeyDown(.escape) {
            Exit()
        }
        
        if !supports3D {
            let movementDelta = dt * 2.0
            position.X += velocity.X * movementDelta
            position.Y += velocity.Y * movementDelta
            
            let viewport = graphics.GraphicsDevice.Viewport
            let logoSize: Float = 256.0
            
            let minX = logoSize / 2
            let minY = logoSize / 2
            let maxX = Float(viewport.Width) - minX
            let maxY = Float(viewport.Height) - minY
            
            if position.X < minX || position.X > maxX {
                velocity.X *= -1
                position.X = max(minX, min(position.X, maxX))
            }
            if position.Y < minY || position.Y > maxY {
                velocity.Y *= -1
                position.Y = max(minY, min(position.Y, maxY))
            }
        }
        
        if rendererBannerSeconds > 0 {
            rendererBannerSeconds -= dt
        }
    }

    func Draw(gameTime: GameTime) {
        graphics.GraphicsDevice.Clear(.cornflowerBlue)
        
        if supports3D {
            Draw3DCube()
        } else {
            Draw2DLogo()
        }
        
        if rendererBannerSeconds > 0 {
            DrawRendererBanner()
        }
        
        drawnFrames += 1
        if smokeTest && drawnFrames >= 10 {
            print("Smoke test passed (\(drawnFrames) frames)")
            Exit()
        }
    }

    private func Draw2DLogo() {
        guard let batch = spriteBatch, let tex = logo else { return }
        
        let motion = animationSeconds * 2.0
        let _scale = 0.96 + 0.12 * sin(motion)
        
        batch.Begin()
        batch.Draw(tex, position, .white)
        batch.End()
    }

    private func Draw3DCube() {
        guard let effect = cubeEffect else { return }
        
        let viewport = graphics.GraphicsDevice.Viewport
        let aspect = Float(viewport.Width) / Float(viewport.Height)
        
        let motion = animationSeconds * 2.0
        let scale = 0.88 + 0.10 * sin(motion * 0.48)
        
        var world = Matrix.createScale(scale)
        world = world * Matrix.createRotationY(motion * 0.55)
        world = world * Matrix.createRotationX(motion * 0.35)
        
        effect.World = world
        effect.View = Matrix.createLookAt(position: Vector3(0, 0, 6), target: .zero, up: .up)
        effect.Projection = Matrix.createPerspectiveFieldOfView(fieldOfView: 0.7853982, aspectRatio: aspect, nearPlaneDistance: 0.1, farPlaneDistance: 100.0)
        
        effect.Apply()
        // Primitive drawing would happen here
    }

    private func DrawRendererBanner() {
        guard let batch = spriteBatch, let tex = solid else { return }
        let viewport = graphics.GraphicsDevice.Viewport
        
        let name = rendererName.uppercased()
        let glyphCols = (name.count * 6) - 1
        let pixelSize = max(1, min(8, (viewport.Width - 48) / max(1, glyphCols)))
        
        let textW = glyphCols * pixelSize
        let textH = 7 * pixelSize
        let textX = (viewport.Width - textW) / 2
        let textY = viewport.Height - textH - 24
        
        batch.Begin()
        // Background
        batch.DrawRect(tex, [Float(textX - 8), Float(textY - 8), Float(textW + 16), Float(textH + 16)], Color(255, 255, 255, 180))
        
        for (i, char) in name.enumerated() {
            let rows = getGlyphRows(char)
            let charX = textX + i * 6 * pixelSize
            for row in 0..<7 {
                let rowData = rows[row]
                for col in 0..<5 {
                    if (rowData >> (4 - col)) & 1 == 1 {
                        batch.DrawRect(tex, [Float(charX + col * pixelSize), Float(textY + row * pixelSize), Float(pixelSize), Float(pixelSize)], .black)
                    }
                }
            }
        }
        batch.End()
    }

    private func getGlyphRows(_ char: Character) -> [UInt8] {
        switch char {
        case "A": return [0x4, 0x0A, 0x11, 0x11, 0x1F, 0x11, 0x11]
        case "B": return [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E]
        case "C": return [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E]
        case "D": return [0x1C, 0x12, 0x11, 0x11, 0x11, 0x12, 0x1C]
        case "E": return [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F]
        case "F": return [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10]
        case "G": return [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F]
        case "H": return [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11]
        case "I": return [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E]
        case "J": return [0x07, 0x02, 0x02, 0x02, 0x02, 0x12, 0x0C]
        case "K": return [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11]
        case "L": return [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F]
        case "M": return [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11]
        case "N": return [0x11, 0x11, 0x19, 0x15, 0x13, 0x11, 0x11]
        case "O": return [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E]
        case "P": return [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10]
        case "Q": return [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D]
        case "R": return [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11]
        case "S": return [0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E]
        case "T": return [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04]
        case "U": return [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E]
        case "V": return [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04]
        case "W": return [0x11, 0x11, 0x11, 0x15, 0x15, 0x1B, 0x11]
        case "X": return [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11]
        case "Y": return [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04]
        case "Z": return [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F]
        case "(": return [0x02, 0x04, 0x08, 0x08, 0x08, 0x04, 0x02]
        case ")": return [0x08, 0x04, 0x02, 0x02, 0x02, 0x04, 0x08]
        case " ": return [0, 0, 0, 0, 0, 0, 0]
        default: return [0x1F, 0x1F, 0x1F, 0x1F, 0x1F, 0x1F, 0x1F]
        }
    }
}
