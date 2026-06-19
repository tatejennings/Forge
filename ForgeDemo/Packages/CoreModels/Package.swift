// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CoreModels",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CoreModels", targets: ["CoreModels"]),
    ],
    targets: [
        .target(name: "CoreModels"),
    ]
)
