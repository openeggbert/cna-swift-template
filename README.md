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

It also reads the surface the binding grew after CNA 0.21.0 landed: the adapter
list and the device's own adapter, the window snapshot, and the two members that
**refuse** -- `GraphicsDevice.Dispose`, because the running game owns the device
and a borrowed handle may not destroy it, and the three-argument
`GraphicsDevice.Present`, because this runtime's only presentation route takes
no rectangle and no window handle. A consumer most needs to see refusals
working, so the canary asserts them rather than avoiding them.

It reads `Game.Content` too, and the three facts a consumer meets first: the
game's manager is **cached** rather than rebuilt per read, a caller can install
their own through `SetContent`, and the two ways a load fails are told apart --
`kindRefused` is an asset kind this runtime has no route for, `missingRefused`
is an asset that is simply not there. **No asset is loaded**, because this
template ships no `.xnb` and a canary that needed one would be testing the
fixture instead of the binding.

The manager's root reads back **empty**: `Game.Content` uses XNA's one-argument
constructor, whose root directory is the empty string. `Content` is also not
Optional -- read outside a Game callback it traps rather than answering nil,
which is why the canary reads it in `LoadContent`.

It runs one real `OcclusionQuery` -- begin, end, wait, read -- and then the two
rules **the binding enforces because CNA does not**: a second `Begin` before the
previous result has been looked at is refused, and a count read from a query
that never finished is refused. This runtime answers a count for a query that
was never begun, so without those two refusals a consumer would read a number
that measured nothing.

It builds and plays a `SoundEffect` too, **from bytes this file writes** -- a
tenth of a second of silence -- because XNA's PCM16 constructor takes a buffer
and this template ships no audio asset. Nothing is audible; what it shows is
that the sound is built, played, controlled through an instance and released,
and that two rules XNA enforces and this runtime does not are enforced by the
binding: the loop flag is fixed at the first `Play`, and a buffer that is not a
whole number of PCM16 frames is refused rather than decoded as a shorter sound.

It also builds a streaming `DynamicSoundEffectInstance` -- from a sample rate
and a channel count, no buffer and no file -- and fills its queue. **This
runtime accepts buffers without limit; XNA refuses past 64**, and the canary
shows the binding enforcing that: `queued=64 pending=64 limitRefused=true`. A
queue that grows without bound fails later and somewhere else.

The last thing it opens is a `Song`, the one Media type reachable without a
media library. **The canary writes its own file and deletes it**: `Song.FromUri`
requires the file to exist -- a URL naming nothing is refused, and the canary
shows that refusal too -- so it writes a minimal PCM16 WAV, opens a song through
it and removes it again. Still no asset ships with this template.

Two of the values it prints are worth reading twice. The window reports a client
area of **0x0** while the device reports a **800x480** viewport: that is what
headless means here, and a canary that quietly used the window's size instead of
the viewport's would draw nothing and say nothing. And the adapter names itself
`\\.\DISPLAY1` with one supported display mode, which is the whole of what this
host has to offer.

There is no XNB, BasicEffect, cube, capability guess, fake banner, synthetic
texture, or Swift-owned frame loop.

One line, printed at exit, is the whole verdict:

```text
CNA_SWIFT_CANARY requested=600 updates=601 draws=600 viewport=800x480
texture=128x128 offscreen=64x64 adapters=1 name=\\.\DISPLAY1 default=true
modes=1 reach=true window=handle=0 client=0x0 resizing=false
device=isDisposed=false disposeRefused=true presentRefused=true
content=root= cached=true installed=true kindRefused=true missingRefused=true
query=pixels=1 waited=0 rearmRefused=true earlyCountRefused=true
audio=played=true ms=100 state=Stopped queued=64 pending=64 limitRefused=true
loopRefused=true badBufferRefused=true master=1.0
song=name=canary track track=0 missingRefused=true readAfterDisposeRefused=true
```

`waited=0` says the query completed before the first check, and `pixels=1` is
what this renderer counted -- not a number to read as a scene measurement, but
proof the round trip reaches the GPU path and comes back.

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
