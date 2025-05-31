// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcodeproj-mcp-server",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "xcodeproj-mcp-server",
            targets: ["xcodeproj-mcp-server"]
        ),
        .library(
            name: "XcodeProjectMCP",
            targets: ["XcodeProjectMCP"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.9.0"),
        .package(url: "https://github.com/tuist/xcodeproj", from: "9.4.2")
    ],
    targets: [
        .target(
            name: "XcodeProjectMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "XcodeProj", package: "xcodeproj")
            ]
        ),
        .executableTarget(
            name: "xcodeproj-mcp-server",
            dependencies: [
                "XcodeProjectMCP"
            ]
        ),
        .testTarget(
            name: "XcodeProjectMCPTests",
            dependencies: [
                "XcodeProjectMCP"
            ]
        ),
    ]
)
