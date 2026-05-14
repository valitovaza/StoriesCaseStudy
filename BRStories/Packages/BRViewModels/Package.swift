// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "BRViewModels",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "BRViewModels",
            targets: ["BRViewModels"]
        ),
    ],
    dependencies: [
        .package(path: "../BRShared/"),
    ],
    targets: [
        .target(
            name: "BRViewModels",
            dependencies: ["BRShared"]
        ),
        .testTarget(
            name: "BRViewModelTests",
            dependencies: ["BRShared", "BRViewModels"]),
    ],
    swiftLanguageModes: [.v6]
)
