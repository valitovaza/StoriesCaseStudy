// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "BRShared",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(
            name: "BRShared",
            targets: ["BRShared"]
        ),
    ],
    targets: [
        .target(
            name: "BRShared"
        ),
    ],
    swiftLanguageModes: [.v6]
)
