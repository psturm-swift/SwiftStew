// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftStew",
    platforms: [
        .macOS(.v10_15), .iOS(.v15), .watchOS(.v8), .tvOS(.v15), .driverKit(.v21), .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "ConcurrencyStew",
            targets: ["ConcurrencyStew"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ConcurrencyStew",
            dependencies: []),
        .testTarget(
            name: "ConcurrencyStewTests",
            dependencies: ["ConcurrencyStew"]),
    ]
)
