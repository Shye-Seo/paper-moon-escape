// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PaperMoonCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "PaperMoonCore", targets: ["PaperMoonCore"])
    ],
    targets: [
        .target(name: "PaperMoonCore", path: "Sources/PaperMoonCore"),
        .testTarget(
            name: "PaperMoonCoreTests",
            dependencies: ["PaperMoonCore"],
            path: "Tests/PaperMoonCoreTests"
        )
    ]
)
