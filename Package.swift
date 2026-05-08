// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ds-mon",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ds-mon",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
