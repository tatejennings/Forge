// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreInfrastructure",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreInfrastructure", targets: ["CoreInfrastructure"]),
    ],
    dependencies: [
        .package(path: "../CoreModels"),
        .package(path: "../CoreNetworking"),
        .package(path: "../../../"),
    ],
    targets: [
        .target(
            name: "CoreInfrastructure",
            dependencies: [
                "CoreModels",
                "CoreNetworking",
                .product(name: "Forge", package: "Forge"),
            ]
        ),
    ]
)
