// swift-tools-version: 5.10

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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
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
