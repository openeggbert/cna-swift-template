// SPDX-License-Identifier: MIT

import CNA
import Foundation

enum HelloGameError: Error, CustomStringConvertible {
    case missingLogo(String)
    case invalidFrameLimit(String)
    case noGraphicsDevice

    var description: String {
        switch self {
        case .missingLogo(let path): return "could not open the project-owned PNG at \(path)"
        case .invalidFrameLimit(let value): return "--frames requires a positive integer, got \(value)"
        case .noGraphicsDevice:
            return "the registered graphics device service produced no device"
        }
    }
}

final class HelloGame: Microsoft.Xna.Framework.Game {
    private let requestedFrames: Int
    private var graphics: Microsoft.Xna.Framework.GraphicsDeviceManager?
    private var spriteBatch: Microsoft.Xna.Framework.Graphics.SpriteBatch?
    private var logo: Microsoft.Xna.Framework.Graphics.Texture2D?
    private var position = Microsoft.Xna.Framework.Vector2.Zero
    private var velocity = Microsoft.Xna.Framework.Vector2(104, 74)
    private var animationSeconds: Float = 0

    private(set) var UpdateCallbacks = 0
    private(set) var DrawCallbacks = 0
    private(set) var NativeViewport: Microsoft.Xna.Framework.Graphics.Viewport?
    private(set) var OffscreenTarget: String = "none"

    /// `Game.GraphicsDevice` resolves the graphics device SERVICE out of
    /// `Game.Services` and returns its Optional device, which is what XNA's
    /// own getter does. `GraphicsDeviceManager` is the registered producer.
    private func requireDevice() throws -> Microsoft.Xna.Framework.Graphics.GraphicsDevice {
        guard let device = try GraphicsDevice else { throw HelloGameError.noGraphicsDevice }
        return device
    }

    init(frames: Int) throws {
        requestedFrames = frames
        try super.init()
        graphics = try Microsoft.Xna.Framework.GraphicsDeviceManager(game: self)
    }

    override func Initialize() throws {
        let viewport = try requireDevice().Viewport
        NativeViewport = viewport
        position = Microsoft.Xna.Framework.Vector2(
            Float(viewport.Width) * 0.5,
            Float(viewport.Height) * 0.5
        )
    }

    override func LoadContent() throws {
        let path = FileManager.default.currentDirectoryPath + "/Content/logo.png"
        guard let stream = InputStream(fileAtPath: path) else { throw HelloGameError.missingLogo(path) }
        let device = try requireDevice()
        logo = try Microsoft.Xna.Framework.Graphics.Texture2D.FromStream(device, stream: stream)
        spriteBatch = try Microsoft.Xna.Framework.Graphics.SpriteBatch(graphicsDevice: device)

        // One small demonstration that a RenderTarget2D IS a Texture2D: the
        // target is created, held as its base type, bound, the backbuffer is
        // restored, and it is released. Public API only, and no pixel is
        // claimed -- the qualified renderer has no window.
        let target = try Microsoft.Xna.Framework.Graphics.RenderTarget2D(
            graphicsDevice: device, width: 64, height: 64)
        let asTexture: Microsoft.Xna.Framework.Graphics.Texture2D = target
        try device.SetRenderTarget(target)
        try device.SetRenderTarget(nil)
        OffscreenTarget = "\(asTexture.Width)x\(asTexture.Height)"
        try target.Dispose()
    }

    override func Update(_ gameTime: Microsoft.Xna.Framework.GameTime) throws {
        UpdateCallbacks += 1
        let duration = gameTime.ElapsedGameTime.components
        let elapsed = Float(duration.seconds) + Float(duration.attoseconds) * 1e-18
        animationSeconds += elapsed

        if try Microsoft.Xna.Framework.Input.Keyboard.GetState().IsKeyDown(.Escape) {
            try Exit()
            return
        }

        position = position + velocity * elapsed
        let viewport = try requireDevice().Viewport
        let halfWidth = Float(logo?.Width ?? 0) * 0.5
        let halfHeight = Float(logo?.Height ?? 0) * 0.5
        let maximumX = Float(viewport.Width) - halfWidth
        let maximumY = Float(viewport.Height) - halfHeight
        if position.X < halfWidth || position.X > maximumX {
            velocity.X = -velocity.X
            position.X = Microsoft.Xna.Framework.MathHelper.Clamp(position.X, min: halfWidth, max: maximumX)
        }
        if position.Y < halfHeight || position.Y > maximumY {
            velocity.Y = -velocity.Y
            position.Y = Microsoft.Xna.Framework.MathHelper.Clamp(position.Y, min: halfHeight, max: maximumY)
        }
    }

    override func Draw(_ gameTime: Microsoft.Xna.Framework.GameTime) throws {
        guard let spriteBatch, let logo else { return }
        try requireDevice().Clear(.CornflowerBlue)
        let rotation = animationSeconds * 0.8
        let scale = 0.85 + 0.15 * sin(animationSeconds * 2)
        let origin = Microsoft.Xna.Framework.Vector2(Float(logo.Width) * 0.5, Float(logo.Height) * 0.5)
        try spriteBatch.Begin()
        try spriteBatch.Draw(
            logo,
            position: position,
            sourceRectangle: nil,
            color: .White,
            rotation: rotation,
            origin: origin,
            scale: scale,
            effects: .None,
            layerDepth: 0
        )
        try spriteBatch.End()
        DrawCallbacks += 1
        if DrawCallbacks == requestedFrames { try Exit() }
    }

    func qualificationLine() -> String {
        let dimensions = "\(logo?.Width ?? 0)x\(logo?.Height ?? 0)"
        return "CNA_SWIFT_CANARY requested=\(requestedFrames) updates=\(UpdateCallbacks) " +
            "draws=\(DrawCallbacks) viewport=\(NativeViewport?.Width ?? 0)x\(NativeViewport?.Height ?? 0) " +
            "texture=\(dimensions) offscreen=\(OffscreenTarget)"
    }
}
