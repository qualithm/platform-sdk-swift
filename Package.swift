// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "QualithmPlatform",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [
    .library(name: "QualithmPlatform", targets: ["QualithmPlatform"])
  ],
  targets: [
    .target(name: "QualithmPlatform"),
    .testTarget(name: "QualithmPlatformTests", dependencies: ["QualithmPlatform"]),
    .executableTarget(
      name: "list-devices", dependencies: ["QualithmPlatform"], path: "examples/list-devices"),
  ]
)
