// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureTasks",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FeatureTasks", targets: ["FeatureTasks"]),
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../../../"),
    ],
    targets: [
        .target(
            name: "FeatureTasks",
            dependencies: [
                "CoreModels",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
        .testTarget(
            name: "FeatureTasksTests",
            dependencies: [
                "FeatureTasks",
                "CoreModels",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
    ]
)
