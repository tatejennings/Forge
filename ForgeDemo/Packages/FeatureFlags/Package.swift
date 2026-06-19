// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "FeatureFlags",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FeatureFlags", targets: ["FeatureFlags"]),
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../../../"),
        // To adopt LaunchDarkly, add its SPM package here, e.g.:
        // .package(url: "https://github.com/launchdarkly/ios-client-sdk.git", from: "9.0.0"),
    ],
    targets: [
        .target(
            name: "FeatureFlags",
            dependencies: [
                "CoreModels",
                .product(name: "Forge", package: "Forge"),
                // .product(name: "LaunchDarkly", package: "ios-client-sdk"),
            ]
        ),
        .testTarget(
            name: "FeatureFlagsTests",
            dependencies: ["FeatureFlags", "CoreModels"]
        ),
    ]
)
