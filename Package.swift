// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CNA.Swift.Template",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .visionOS(.v1)
    ],
    dependencies: [
        .package(path: "../cna-swift"),
    ],
    targets: [
        .executableTarget(
            name: "HelloGame",
            dependencies: [
                .product(name: "CNA", package: "cna-swift")
            ],
            path: "Sources"
        ),
    ]
)
