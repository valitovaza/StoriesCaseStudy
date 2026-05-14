// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "BRStoriesUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "BRStoriesUI",
            targets: ["BRStoriesUI"]
        ),
    ],
    dependencies: [
        .package(path: "../BRShared/"),
    ],
    targets: [
        .target(
            name: "BRStoriesUI",
            dependencies: ["BRShared"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
