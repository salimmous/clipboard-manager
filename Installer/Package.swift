// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ClipboardManagerInstaller",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ClipboardManagerInstaller",
            targets: ["ClipboardManagerInstaller"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ClipboardManagerInstaller",
            dependencies: [],
            path: "Sources"
        )
    ]
)