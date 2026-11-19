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
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "mapkit_flutter_objc_gen",
      dependencies: [],
      publicHeadersPath: "."
    ),
    // Swift 5 language mode until upstream Pigeon annotates the mutable static
    // globals its `useFfi: true` Swift generator emits (`#MutableGlobalVariable`
    // in Swift 6).
    .target(
      name: "mapkit_flutter",
      dependencies: [
        "mapkit_flutter_objc_gen",
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ],
      resources: [.process("PrivacyInfo.xcprivacy")],
      swiftSettings: [.swiftLanguageMode(.v5)]
    )
  ]
)
