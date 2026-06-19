// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureSettings",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../DesignSystem"),
        .package(path: "../../../"),
    ],
    targets: [
        .target(
            name: "FeatureSettings",
            dependencies: [
                "CoreModels",
                "DesignSystem",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
        .testTarget(
            name: "FeatureSettingsTests",
            dependencies: [
                "FeatureSettings",
                "CoreModels",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
    ]
)
