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
    private(set) var AdapterLine: String = "none"
    private(set) var WindowLine: String = "none"
    private(set) var DisposalLine: String = "none"
    private(set) var ContentLine: String = "none"
    private(set) var QueryLine: String = "none"
    private(set) var AudioLine: String = "none"

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

        try readAdapterAndWindow(device)
        try readContent()
        try readOcclusionQuery(device)
        try readAudio()
    }

    /// The surface Foundation 77 through 85 added, exercised from outside the
    /// package exactly as a game would.
    ///
    /// Everything here is a **read** or a **refusal**. Nothing opens a window,
    /// nothing changes a display mode, and nothing claims a pixel -- the
    /// qualified renderer has none of those.
    private func readAdapterAndWindow(
        _ device: Microsoft.Xna.Framework.Graphics.GraphicsDevice
    ) throws {
        // The adapter list is filled when the device first exists, which is
        // this binding's stand-in for XNA's class constructor. A consumer
        // reads it; it never asks for it.
        let adapters = Microsoft.Xna.Framework.Graphics.GraphicsAdapter.Adapters
        let adapter = device.Adapter
        let modes = adapter?.SupportedDisplayModes
        var modeCount = 0
        if let modes {
            let cursor = modes.GetEnumerator()
            while (try cursor.Next()) != nil { modeCount += 1 }
        }
        AdapterLine = "\(adapters?.Count ?? 0) name=\(adapter?.DeviceName ?? "none") "
            + "default=\(adapter?.IsDefaultAdapter ?? false) modes=\(modeCount) "
            + "reach=\(adapter?.IsProfileSupported(.Reach) ?? false)"

        // The window is a snapshot too, and its handle is what
        // FindBestDevice's enumeration reads.
        let window = Window
        WindowLine = "handle=\(window?.Handle ?? 0) "
            + "client=\(window?.ClientBounds.Width ?? 0)x\(window?.ClientBounds.Height ?? 0) "
            + "resizing=\(window?.AllowUserResizing ?? false)"

        // Two members that REFUSE, which is the half a consumer most needs to
        // see working: this runtime owns the device, so a borrowed handle may
        // not dispose it, and its only presentation route takes no rectangle.
        var disposeRefused = false
        do { try device.Dispose() } catch { disposeRefused = true }
        var presentRefused = false
        do {
            try device.Present(
                Microsoft.Xna.Framework.Rectangle(0, 0, 8, 8),
                destinationRectangle: nil, overrideWindowHandle: 0)
        } catch { presentRefused = true }
        DisposalLine = "isDisposed=\(device.IsDisposed) "
            + "disposeRefused=\(disposeRefused) presentRefused=\(presentRefused)"
    }

    /// `Game.Content`, and the two refusals a consumer meets first.
    ///
    /// Nothing here loads an asset: this template ships no `.xnb`, and a
    /// canary that needed one would be testing the fixture. What it proves is
    /// that the manager exists inside the lifecycle, that the game's one is
    /// cached rather than rebuilt, that a caller can install their own, and
    /// that the two ways a load can fail are **distinguishable** -- a kind
    /// with no route is refused by name, a missing asset fails through the
    /// route it does have.
    private func readContent() throws {
        // Non-Optional: the getter has no failure path and its return is
        // proven non-null, so there is nothing to unwrap. Outside a callback
        // it would trap, which is why this is read here and not in init.
        let content = Content
        let cached = Content === content

        // A consumer's own manager, installed through the writer. This is the
        // half that needs System.IServiceProvider to be a protocol: Services
        // is a GameServiceContainer, but the constructor takes the interface.
        let mine = try Microsoft.Xna.Framework.Content.ContentManager(
            serviceProvider: Services, rootDirectory: "Content")
        try SetContent(mine)
        let installed = Content === mine

        var kindRefused = false
        do {
            let _: Microsoft.Xna.Framework.Graphics.SpriteFont =
                try mine.Load("any")
        } catch { kindRefused = true }

        var missingRefused = false
        do {
            let _: Microsoft.Xna.Framework.Graphics.Texture2D =
                try mine.Load("no-such-asset")
        } catch { missingRefused = true }

        // Unload leaves it usable; Dispose is what ends it. The manager is
        // registered with the runtime either way, so a consumer who forgets
        // this line does not leak a handle past the game.
        try mine.Unload()
        try mine.Dispose()

        ContentLine = "root=\(content.RootDirectory ?? "nil") cached=\(cached) "
            + "installed=\(installed) kindRefused=\(kindRefused) "
            + "missingRefused=\(missingRefused)"
    }

    /// `OcclusionQuery`, and the two rules the binding enforces because CNA
    /// does not.
    ///
    /// A real round trip -- begin, end, wait, read -- then the two refusals: a
    /// second `Begin` before the result has been looked at, and a count read
    /// from a query that never finished. Both are XNA behaviour that this
    /// runtime would otherwise let through, so a consumer sees them working.
    private func readOcclusionQuery(
        _ device: Microsoft.Xna.Framework.Graphics.GraphicsDevice
    ) throws {
        let query: Microsoft.Xna.Framework.Graphics.OcclusionQuery
        do {
            query = try Microsoft.Xna.Framework.Graphics.OcclusionQuery(
                graphicsDevice: device)
        } catch {
            // A backend with no query object refuses at construction, which is
            // the honest outcome and is printed rather than hidden.
            QueryLine = "unsupported"
            return
        }

        try query.Begin()
        try query.End()
        var spins = 0
        while !query.IsComplete && spins < 10_000 { spins += 1 }
        let count = try query.PixelCount

        // Rearm rule: End without checking IsComplete, then Begin again.
        try query.Begin()
        try query.End()
        var rearmRefused = false
        do { try query.Begin() } catch { rearmRefused = true }
        _ = query.IsComplete

        // A fresh query has nothing to report, and says so.
        let unfinished = try Microsoft.Xna.Framework.Graphics.OcclusionQuery(
            graphicsDevice: device)
        var countRefused = false
        do { _ = try unfinished.PixelCount } catch { countRefused = true }
        try unfinished.Dispose()
        try query.Dispose()

        QueryLine = "pixels=\(count) waited=\(spins) "
            + "rearmRefused=\(rearmRefused) earlyCountRefused=\(countRefused)"
    }

    /// `SoundEffect` and `SoundEffectInstance`, from bytes this file writes.
    ///
    /// **No audio asset ships with this template**, and none is needed: XNA's
    /// PCM16 constructor takes a buffer, so a tenth of a second of silence is
    /// the whole fixture. Nothing is audible; what is demonstrated is that the
    /// sound is built, played, controlled and released, and that the rules XNA
    /// enforces and this runtime does not are enforced by the binding.
    private func readAudio() throws {
        let silence = [UInt8](repeating: 0, count: 1600)  // 800 frames @ 8 kHz
        let effect: Microsoft.Xna.Framework.Audio.SoundEffect
        do {
            effect = try Microsoft.Xna.Framework.Audio.SoundEffect(
                buffer: silence, sampleRate: 8000, channels: .Mono)
        } catch {
            AudioLine = "unsupported"
            return
        }
        try effect.SetName("canary silence")
        let played = try effect.Play()

        let instance = try effect.CreateInstance()
        try instance.SetVolume(0.5)
        try instance.SetIsLooped(true)
        try instance.Play()
        try instance.Stop()
        let state = try instance.State

        // The rule that closes at the first Play: the loop flag is fixed now.
        var loopRefused = false
        do { try instance.SetIsLooped(false) } catch { loopRefused = true }

        // And the one CNA would let through: an odd-length buffer is not a
        // whole number of PCM16 frames.
        var badBufferRefused = false
        do {
            _ = try Microsoft.Xna.Framework.Audio.SoundEffect(
                buffer: [0, 0, 0], sampleRate: 8000, channels: .Mono)
        } catch { badBufferRefused = true }

        // Read BEFORE disposal. `Duration` is infallible, so a released
        // effect answers zero rather than refusing -- which is correct, and
        // reads exactly like a broken duration if the call is in the wrong
        // place. It was, in the first version of this canary.
        //
        // Seconds alone would also report 0 for a tenth of a second.
        let parts = effect.Duration.components
        let ms = Int(parts.seconds) * 1000
            + Int(parts.attoseconds / 1_000_000_000_000_000)

        try instance.Dispose()
        try effect.Dispose()
        // A streaming instance, which is built from parameters rather than a
        // buffer, and the one limit this runtime does not enforce: XNA refuses
        // past 64 pending buffers, and here they simply accumulate.
        let dynamic = try Microsoft.Xna.Framework.Audio
            .DynamicSoundEffectInstance(sampleRate: 8000, channels: .Mono)
        let frame = [UInt8](repeating: 0, count: 64)
        var queued = 0
        var limitRefused = false
        for _ in 0..<80 {
            do { try dynamic.SubmitBuffer(frame); queued += 1 }
            catch { limitRefused = true; break }
        }
        let pending = try dynamic.PendingBufferCount
        try dynamic.Dispose()

        AudioLine = "played=\(played) ms=\(ms) state=\(state) "
            + "queued=\(queued) pending=\(pending) limitRefused=\(limitRefused) "
            + "loopRefused=\(loopRefused) badBufferRefused=\(badBufferRefused) "
            + "master=\(Microsoft.Xna.Framework.Audio.SoundEffect.MasterVolume)"
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
            "texture=\(dimensions) offscreen=\(OffscreenTarget) " +
            "adapters=\(AdapterLine) window=\(WindowLine) device=\(DisposalLine) "
            + "content=\(ContentLine) query=\(QueryLine) audio=\(AudioLine)"
    }
}
