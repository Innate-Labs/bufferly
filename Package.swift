// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Bufferly",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "Bufferly", targets: ["Bufferly"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Bufferly",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BufferlyTests",
            dependencies: ["Bufferly"]
        )
    ]
)
