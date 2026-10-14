// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Bhaptics",
    platforms: [
        .iOS(.v13), .macOS(.v10_15), .visionOS("2.0")
    ],
    products: [
        .library(
            name: "Bhaptics",
            targets: ["BhapticsPlugin"]),
    ],
    targets: [
        .binaryTarget(
            name: "BhapticsPlugin",
            url: "https://github.com/bhaptics/bhaptics-ios/releases/download/1.0.1/BhapticsPlugin.xcframework.zip",
            checksum: "e146c9a0485d84ac390d87ac28ad824488a5430210cf607cc68ad08059e1653b"
        )
    ]
)
