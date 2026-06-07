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
    targets: [
        .target(
            name: "Forge",
            path: "Sources/Forge",
            exclude: ["Forge.docc"],
            swiftSettings: [
                // Build Forge itself under complete strict concurrency so concurrency
                // regressions surface locally, not just in the CI strict job. Keeping
                // swift-tools-version at 5.10 means consumers on the 5.10 toolchain can
                // still depend on Forge; this setting only affects Forge's own target.
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "ForgeTests",
            dependencies: ["Forge"],
            path: "Tests/ForgeTests"
        ),
    ]
)
