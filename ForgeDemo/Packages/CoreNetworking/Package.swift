// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../../../"),
    ],
    targets: [
        .target(
            name: "CoreNetworking",
            dependencies: [
                "CoreModels",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
        .testTarget(
            name: "CoreNetworkingTests",
            dependencies: ["CoreNetworking", "CoreModels"]
        ),
    ]
)
