// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "KeepAwake",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "KeepAwake", targets: ["KeepAwake"]),
        .executable(name: "KeepAwakeAssertionQA", targets: ["KeepAwakeAssertionQA"])
    ],
    targets: [
        .target(name: "KeepAwakeCore"),
        .executableTarget(name: "KeepAwake", dependencies: ["KeepAwakeCore"]),
        .executableTarget(name: "KeepAwakeAssertionQA", dependencies: ["KeepAwakeCore"]),
        .testTarget(name: "KeepAwakeCoreTests", dependencies: ["KeepAwakeCore"])
    ]
)
