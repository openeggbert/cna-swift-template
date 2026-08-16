# CNA Swift Template

A cross-platform game template for Swift using the CNA (Common Native Abstraction) framework.

## Features

- **XNA 4.0 API**: Familiar PascalCase API for Game lifecycle.
- **Multi-platform**: Supports macOS, iOS, tvOS, and visionOS.
- **Adaptive Rendering**: Automatically switches between 3D (HiDef) and 2D (Reach) modes.
- **Smoke Test Support**: Includes `--smoke-test` flag for CI/CD validation.

## Prerequisites

- Xcode 15+
- Swift 5.9+

## Getting Started

### macOS (Desktop)

```bash
swift run
```

### iOS / tvOS / visionOS

1. Open the project in Xcode (or use `swift package generate-xcodeproj` if needed, though Swift Packages are now first-class in Xcode).
2. Select your target device/simulator.
3. Build and Run.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
