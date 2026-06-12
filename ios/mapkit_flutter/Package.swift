// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "mapkit_flutter",
  platforms: [
    .iOS("17.0")
  ],
  products: [
    // Hyphenated product name avoids collision with the target name.
    .library(name: "mapkit-flutter", targets: ["mapkit_flutter"])
  ],
  targets: [
    .target(name: "mapkit_flutter")
  ]
)
