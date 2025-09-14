// Package.swift (for Vapor)
import PackageDescription

let package = Package(
    name: "FriendsOnlyBackend",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.85.0"),
    ],
    targets: [
        .executableTarget(
            name: "FriendsOnlyBackend",
            dependencies: [.product(name: "Vapor", package: "vapor")]),
        .testTarget(
            name: "FriendsOnlyBackendTests",
            dependencies: ["FriendsOnlyBackend"]),
    ]
)
