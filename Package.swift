// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClipboardManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClipboardManager",
            targets: ["ClipboardManager"]
        ),
        .library(
            name: "ClipboardManagerCore",
            targets: ["ClipboardManagerCore"]
        )
    ],
    targets: [
        .target(
            name: "ClipboardManagerCore",
            dependencies: [],
            path: "Sources/ClipboardManagerCore"
        ),
        .executableTarget(
            name: "ClipboardManager",
            dependencies: ["ClipboardManagerCore"],
            path: "Sources/ClipboardManager"
        ),
        .testTarget(
            name: "ClipboardManagerTests",
            dependencies: ["ClipboardManagerCore"],
            path: "Tests/ClipboardManagerTests"
        )
    ]
)
