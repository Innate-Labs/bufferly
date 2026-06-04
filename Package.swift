// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Bufferly",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Bufferly", targets: ["Bufferly"])
    ],
    targets: [
        .executableTarget(
            name: "Bufferly"
        )
    ]
)
