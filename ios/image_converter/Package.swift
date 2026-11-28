// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "image_converter",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "image-converter", targets: ["image_converter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "image_converter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // This plugin uses no required-reason APIs, so its privacy
                // manifest is empty and not bundled. If that changes, describe
                // the usage in PrivacyInfo.xcprivacy and uncomment this line
                // (and the matching line in image_converter.podspec).
                // .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
