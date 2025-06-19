// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftyTIV",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "SwiftyTIV",
            targets: ["SwiftyTIV"]
        ),
        .executable(
            name: "stiv",
            targets: ["SwiftyTIVCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "SwiftyTIV",
            dependencies: []
        ),
        .executableTarget(
            name: "SwiftyTIVCLI",
            dependencies: [
                "SwiftyTIV",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SwiftyTIVTests",
            dependencies: ["SwiftyTIV"]
        )
    ]
)