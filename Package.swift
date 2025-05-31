// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcodeproj-mcp-server",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.1.0"),
        .package(url: "https://github.com/tuist/xcodeproj", from: "8.23.0")
    ],
    targets: [
        .executableTarget(
            name: "xcodeproj-mcp-server",
            dependencies: [
                .product(name: "ModelContextProtocol", package: "swift-sdk"),
                .product(name: "XcodeProj", package: "xcodeproj")
            ]
        ),
    ]
)
