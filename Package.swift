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
            url: "https://github.com/bhaptics/bhaptics-ios/releases/download/1.0.0/BhapticsPlugin.xcframework.zip",
            checksum: "72723a88488e95be4fd48f347936b2fb3039a0ef6f137a0c6e175db7f4773a3d"
        )
    ]
)
