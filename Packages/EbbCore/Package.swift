// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EbbCore",
    products: [.library(name: "EbbCore", targets: ["EbbCore"])],
    targets: [
        .target(name: "EbbCore"),
        .testTarget(name: "EbbCoreTests", dependencies: ["EbbCore"]),
    ]
)
