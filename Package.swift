// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "cget",
    dependencies: [
        .Package(url: "https://github.com/kylef/Commander", majorVersion: 0, minor: 6),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger", majorVersion: 1, minor: 7)
    ]
)
