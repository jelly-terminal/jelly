// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "JellyTerminal",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "JellyTerminal", targets: ["JellyTerminal"]),
    ],
    dependencies: [
        .package(path: "../JellyCore"),
        .package(url: "https://github.com/mxvsh/SwiftTerm", branch: "jelly"),
    ],
    targets: [
        .target(
            name: "JellyTerminal",
            dependencies: ["JellyCore", .product(name: "SwiftTerm", package: "SwiftTerm")]
        ),
        .testTarget(name: "JellyTerminalTests", dependencies: ["JellyTerminal"]),
    ]
)
