// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftStew",
    platforms: [.macOS(.v12), .iOS(.v12), .watchOS(.v8), .tvOS(.v12), .macCatalyst(.v15), .driverKit(.v21)],
    products: [
        .library(
            name: "ConcurrencyStew",
            type: .static,
            targets: ["ConcurrencyStew"]),
        .library(
            name: "SwiftUIStew",
            type: .static,
            targets: ["SwiftUIStew"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftUIStew",
            dependencies: []),
        .target(
            name: "ConcurrencyStew",
            dependencies: []),
        .testTarget(
            name: "ConcurrencyStewTests",
            dependencies: ["ConcurrencyStew"]),
    ]
)
