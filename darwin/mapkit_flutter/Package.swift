// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "mapkit_flutter",
  platforms: [
    .iOS("17.0"),
    .macOS("14.0")
  ],
  products: [
    // Hyphenated product name avoids collision with the target name.
    .library(name: "mapkit-flutter", targets: ["mapkit_flutter"])
  ],
  targets: [
    // swiftLanguageMode defaults to v6 under tools 6.0 — data-race safety is
    // compiler-enforced, matching the podspec's swift_version = '6.0'.
    .target(name: "mapkit_flutter")
  ]
)
