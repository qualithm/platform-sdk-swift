// swift-tools-version: 6.2

import PackageDescription

// A deprecated API use is an error; other warnings stay warnings.
let deprecationsAreErrors: [SwiftSetting] = [.treatWarning("DeprecatedDeclaration", as: .error)]

let package = Package(
  name: "QualithmPlatform",
  platforms: [.macOS(.v15), .iOS(.v18)],
  products: [
    .library(name: "QualithmPlatform", targets: ["QualithmPlatform"])
  ],
  targets: [
    // Exempt: its generated models use their own deprecated fields.
    .target(name: "QualithmPlatform"),
    .testTarget(
      name: "QualithmPlatformTests", dependencies: ["QualithmPlatform"],
      swiftSettings: deprecationsAreErrors),
    .executableTarget(
      name: "list-devices", dependencies: ["QualithmPlatform"], path: "examples/list-devices",
      swiftSettings: deprecationsAreErrors),
  ]
)
