// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ForgeDemoPackages",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
        .library(name: "CoreNetworking", targets: ["CoreNetworking"]),
        .library(name: "CoreInfrastructure", targets: ["CoreInfrastructure"]),
        .library(name: "FeatureTasks", targets: ["FeatureTasks"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../../../"),
    ],
    targets: [
        .target(name: "CoreModels", dependencies: []),
        .target(name: "CoreNetworking", dependencies: ["CoreModels"]),
        .target(name: "CoreInfrastructure", dependencies: ["CoreModels", "CoreNetworking"]),
        .target(name: "FeatureTasks", dependencies: ["CoreModels", .product(name: "Forge", package: "Forge")]),
        .target(name: "FeatureSettings", dependencies: ["CoreModels", .product(name: "Forge", package: "Forge")]),
        .testTarget(name: "CoreNetworkingTests", dependencies: ["CoreNetworking", "CoreModels"]),
        .testTarget(name: "FeatureTasksTests", dependencies: ["FeatureTasks", "CoreModels", .product(name: "Forge", package: "Forge")]),
        .testTarget(name: "FeatureSettingsTests", dependencies: ["FeatureSettings", "CoreModels", .product(name: "Forge", package: "Forge")]),
    ]
)
