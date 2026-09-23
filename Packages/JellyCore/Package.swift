// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "JellyCore",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "JellyCore", targets: ["JellyCore"]),
    ],
    targets: [
        .target(name: "JellyCore", resources: [.copy("Resources/Themes")]),
        .testTarget(name: "JellyCoreTests", dependencies: ["JellyCore"]),
    ]
)
