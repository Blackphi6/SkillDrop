// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SkillDrop",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SkillDrop", targets: ["SkillDrop"])
    ],
    targets: [
        .executableTarget(
            name: "SkillDrop",
            path: "Sources/SkillDrop"
        )
    ]
)
