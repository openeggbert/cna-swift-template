# CNA Swift desktop canary

This is one deliberately small XNA-shaped Swift canary. It subclasses
`Microsoft.Xna.Framework.Game`, and CNA's canonical C ABI drives the lifecycle.
It opens the project-owned `Content/logo.png` through the mapped
`Texture2D.FromStream` route, reads the native viewport, clears the real device,
submits a rotating/scaling/moving sprite through SpriteBatch, polls native
keyboard state, and requests native Game exit at an exact Draw callback count.

It also creates one `RenderTarget2D`, holds it as the `Texture2D` it derives
from, binds it and restores the backbuffer -- a public-API demonstration that
the inheritance is real. No pixel is claimed: the qualified renderer has no
window.

There is no Content/XNB, BasicEffect, cube, capability guess, fake banner,
synthetic texture, or Swift-owned frame loop.

## Qualified boundary

Linux x86-64 with Swift 6.0.3 and an external CNA C ABI 0.21.0 HEADLESS library
is the qualified boundary. The binding admits CNA's own published consumer
window — major `0` exactly, minor `21` or later — so an earlier generation is
rejected by name. HEADLESS executes the real graphics route but provides no
visible window, so visible output remains backend-blocked. macOS, iOS, tvOS,
visionOS, Windows, and Web/Wasm are unqualified.

From this repository root, provide the external library explicitly:

```bash
CNA_NATIVE_LIBRARY=/absolute/path/to/libcna_c_api.so swift run HelloGame --frames 60
CNA_NATIVE_LIBRARY=/absolute/path/to/libcna_c_api.so swift run HelloGame --frames 600
```

The command prints actual Update and Draw callback counts plus native viewport
and decoded texture dimensions. The Swift package dependency is a sibling path
for template development only; the binding's qualification separately builds
an independent consumer from its exact source archive.
