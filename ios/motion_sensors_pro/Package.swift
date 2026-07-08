// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "motion_sensors_pro",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "motion-sensors-pro",
            targets: ["motion_sensors_pro"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "motion_sensors_pro",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
