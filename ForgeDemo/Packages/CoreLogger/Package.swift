// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreLogger",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreLogger", targets: ["CoreLogger"]),
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../../../"),
    ],
    targets: [
        .target(
            name: "CoreLogger",
            dependencies: [
                "CoreModels",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
        .testTarget(
            name: "CoreLoggerTests",
            dependencies: ["CoreLogger", "CoreModels"]
        ),
    ]
)
