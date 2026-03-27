// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Forge",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "Forge",
            targets: ["Forge"]
        ),
    ],
    targets: [
        .target(
            name: "Forge"
        ),
        .testTarget(
            name: "ForgeTests",
            dependencies: ["Forge"]
        ),
    ]
)
