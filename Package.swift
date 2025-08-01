
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClipboardManager",
    platforms: [
        .macOS(.v13) // Supports macOS 13.0 (Ventura) and later
    ],
    products: [
        .executable(
            name: "ClipboardManager",
            targets: ["ClipboardManager"]
        )
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .executableTarget(
            name: "ClipboardManager",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("../svgviewer-output.svg")
            ]
        )
    ]
)