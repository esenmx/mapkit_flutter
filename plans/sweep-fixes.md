---
status: in-progress
created: 2026-10-03
updated: 2026-10-04
---

# Plan: mapkit_flutter 0.4.0 — pigeon 29, native teardown, Swift fixes, selection/feature callbacks, fleet hygiene
Every section below is filled from the current tree; a placeholder left in is a plan not done. Headings stay as written — the executor navigates by them.

Frontmatter `status` is the plan's lifecycle, one owner per transition: `draft` → `approved` (planner, on user approval, before commit) → `in-progress` (executor, before Phase 1) → deleted (executor's last commit, once every § Verification step ran and passed — one that couldn't run keeps it `in-progress`, logged to the § Found tracker). Plans are ephemeral: git is the archive. `outdated` — whoever finds § Files no longer matching the tree; an outdated plan is re-grounded or replaced, never executed. Every transition bumps `updated`.

## Progress
- [x] Phase 1: Pigeon 29 + SPM foundation
- [x] Phase 2: Native oracle harness, host teardown, geodesic crash
- [x] Phase 3: Dart bug fixes
- [x] Phase 4: Swift bug fixes
- [x] Phase 5: Snapshot fidelity
- [x] Phase 6: Selection, map-feature and continuous-camera callbacks; iOS 18 POI categories
- [x] Phase 7: Packaging
- [x] Phase 8: Repo meta, lint config, pubspec
- [x] Phase 9: Docs and agent skill
- [x] Phase 10: CI
- [ ] Phase 11: Release 0.4.0

## Problem
The working tree asks for pigeon ^28 while the committed codegen is pigeon 27 plus two hand-patches; regenerating breaks the Swift build. Every unmounted map leaks its native `MKMapView`, `MapKitViewHost` and `CLLocationManager`; a dozen Swift and Dart defects drop updates, taps and styles; the example cannot build without CocoaPods and crashes on macOS 27. After this lands: codegen is a pure, CI-guarded generator step on pigeon 29; maps tear down; every fixed defect has a test that failed first (Dart unit, macOS/iOS XCTest, or macOS integration); selection, map-feature and continuous camera callbacks exist; packaging, docs, skill and CI match the fleet template; 0.4.0 is ready to publish (by the maintainer).

## Invariants
- Generated files (`lib/src/messages.g.dart`, `darwin/mapkit_flutter/Sources/mapkit_flutter/messages.g.swift`, `test/mk_map_view_controller_mock_test.mocks.dart`) are only ever produced by `dart run pigeon --input pigeons/messages.dart && dart format lib/src/messages.g.dart` and `dart run build_runner build --delete-conflicting-outputs`. Never hand-edit; CI diffs them.
- Wire types keep the `Platform` prefix (schema header explains why); public Dart names come from `typedef`s in `lib/src/mk_enums.dart`.
- Host-side handler removal goes through `ConnectionTrackingMessenger.removeAllHandlers()` (`cleanUpConnection`). Never `MapKitHostApiSetup.setUp(…, api: nil, …)`: on macOS the engine stores the nil handler and the next message on that channel SIGSEGVs (`engine/src/flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine.mm` under the Flutter SDK root: `setMessageHandlerOnChannel:binaryMessageHandler:` wraps `nil` in a `FlutterEngineHandlerInfo`; `engineCallbackOnPlatformMessage:` then calls the nil block). Only the macOS leak test catches a regression.
- Never subclass `MKGeodesicPolyline`: on the 27 SDKs its `init(coordinates:count:)` factory returns a plain `MKGeodesicPolyline` (instance size 112 vs a subclass's 136), so subclass stored properties write past the object (the example's geodesic polyline crashes the app on macOS 27.0.1). `MKPolyline`, `MKPolygon` and `MKCircle` subclasses are unaffected (verified).
- Host → Dart events go through `MapKitFlutterApi.send { try await $0.onX(…) }`; capture every value (camera, coordinate, message, id) in a `let` before the closure so the event carries the state at send time. Tasks created on the main actor start in creation order, so event order is preserved.
- Swift stays in Swift 6 language mode with zero warnings (`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` in CI's native job). `MapKitViewHost`, `FlutterMapView`, `TouchHandler` stay `@MainActor`.
- `MKMapViewController` stays an `abstract interface class` (tests mock it); `MKMapViewControllerImpl` and `MKMapViewEventSink` stay `@internal` and hidden from the barrel.
- The example is a Swift Package Manager project (no Podfile). Deployment floors: iOS 17.0, macOS 14.0 (podspec, `Package.swift`, both example Xcode projects).
- `git-committer` commits **and pushes** by default. Every dispatch of it in this plan must say **"commit only, do not push"**, except the one push the final phase names. A phase commit must never reach the remote before that.

## Decisions
- **Pigeon:** pin `pigeon: 29.0.6` exactly (the generated header embeds the version; a caret would turn the CI drift guard red on any patch release with no repo change; a Dependabot bump must regenerate in its PR). FlutterApi methods use pigeon 29's `async` API (`@MainActor … async throws`), replacing the `@Sendable` hand-patch. The two `@async` host methods (`takeSnapshot`, `openLookAround`) become `@asyncCallback`: pigeon 29's `async throws` host handlers do not compile in Swift 6 mode (`sending 'api' risks causing data races`, `sending 'reply' …` in the generated `setUp`), while completion-style handlers compile clean and keep today's Swift signatures. Planner default deviating from "async Swift API" in D3 for these two methods only.
- **Native oracles:** migrate the example to SPM by regenerating `example/ios` and `example/macos` with `flutter create` (no CocoaPods on the dev machine). Native fixes are proven by XCTest in `example/{macos,ios}/RunnerTests` with `@testable import mapkit_flutter` against a `MapKitViewHost(messenger:id:)` built on a fake `FlutterBinaryMessenger`, plus the macOS integration leak test. iOS-only defects run on the local `iPhone 15, OS=17.5` simulator; CI runs iOS XCTest on the runner's default simulator runtime. The example bundle id becomes the `flutter create` default `dev.mapkit.flutter.mapkitFlutterExample` (was `dev.mapkit.flutter.example` on iOS).
- **copyWith:** nullable parameters take `Object? x = unset` and resolve with `identical(x, unset) ? this.x : x as T?` — source-compatible for every existing call; the declined alternatives are `ValueGetter<T?>?` (source-breaking) and a freezed-style callable (changes the member kind). Planner default.
- **Duplicate ids:** debug `assert` in `_MKMapViewState.initState`/`didUpdateWidget`, and `initialize` sends one object per id, last wins (same as the rebuild diff).
- **Overlay taps:** the wire flag is `consumeTapEvents || onTap != null`; overlay `==`/`hashCode` include `onTap != null`; the `consumeTapEvents` parameter stays (not deprecated). A tap fires only the top-most visible consuming overlay (levels `.aboveLabels` then `.aboveRoads`, each top-first); hidden overlays never consume. Behaviour change listed under `### Changed`.
- **Native behaviour:** `userTrackingMode` is re-applied only when the Dart value changes (`onUserTrackingModeChanged` is a deferred feature); `wasDragged` is removed, so Dart is the source of truth and an annotation whose coordinate the app ignored after a drag snaps back on its next changed rebuild; custom-image `calloutOffset = .zero`.
- **Snapshots:** options carry the map's configuration (rebuilt from the last Dart configuration), camera and light/dark appearance; the deprecated `showsBuildings`/`pointOfInterestFilter`/`scale` setters are no longer used. `MKMapSnapshotOptions.showsBuildings` stays (doc says "no effect"); its removal is a later breaking change.
- **New POI categories:** only the 33 iOS 18 / macOS 15 ones, appended after `zoo`, `#available(iOS 18.0, macOS 15.0, *)`-gated (unavailable → dropped from filters). The iOS 27 categories are out.
- **Map features:** `onMapFeatureSelected` is iOS-only (MapKit has no `selectableMapFeatures` on macOS); payload is feature type, coordinate, title, POI category — no map-item lookup.
- **Selection:** `onSelect` fires for user and programmatic selection, after `onTap` (user only); `onDeselect` on every deselection.
- **fitCoordinates:** new `padding` (fraction of span added per side, default `0`) and `minimumSpan` (degrees, default `0.005`).
- **Packaging:** `pigeons/` stays in the archive; `.pubignore` stays (accurate header). Podspec loses `-warnings-as-errors`; CI enforces warnings on the SPM build instead. A CI-only CocoaPods probe job verifies the podspec.
- **CI:** stays on `macos-15` runners; every macOS job runs `flutter config --enable-swift-package-manager` explicitly. Coverage artifact upload is dropped (fleet: no coverage upload).
- **Git:** commit on `master` after each passing phase via the `git-committer` agent (conventional commits); push and watch CI only in Phase 11. Never `dart pub publish`, never tags or GitHub releases, never repository settings.

## Files
|Path|Action|Exact symbols|
|--|--|--|
|`pubspec.yaml`|modify|fold bump, `pigeon: 29.0.6`; drop `homepage`, `documentation`; `version: 0.4.0`|
|`pigeons/messages.dart` → `lib/src/messages.g.dart`, `darwin/…/messages.g.swift`; `test/mk_map_view_controller_mock_test.mocks.dart`|modify → regenerate|header, `swiftOut`, `@asyncCallback`, `dispose()`, `PlatformMapFeatureType`, `PlatformMapFeature`, 33 POI cases, `onAnnotationSelect/Deselect`, `onMapFeatureSelected`|
|`ios/`|delete|stray generated Swift copy|
|`darwin/mapkit_flutter/Package.swift`, `darwin/mapkit_flutter.podspec`, `darwin/…/PrivacyInfo.xcprivacy` (create)|modify|FlutterFramework dep, resources; podspec flags, `resource_bundles`, `s.version`|
|`darwin/…/Utils/MapKitFlutterApi+Send.swift`, `darwin/…/Utils/ConnectionTrackingMessenger.swift`|create|`send(_:)`; `ConnectionTrackingMessenger`, `removeAllHandlers()`|
|`darwin/…/MapView/MapKitViewHost.swift`, `FlutterMapView.swift`|modify|`init(messenger:id:)`, `dispose()`, `tearDown()`, tile replace, `mapViewDidChangeVisibleRegion`, `SnapshotInput`, `makeSnapshotOptions`, `startSnapshot`, `appliedConfiguration`, `makeMapConfiguration`, tracking gate, tracking button, iOS camera recognizers removed|
|`darwin/…/Annotations/AnnotationController.swift`, `FlutterAnnotation.swift`, `Overlays/FlutterPolyline.swift`, `Utils/TouchHandler.swift`, `Utils/PointOfInterestCategory+MapKit.swift`, `Utils/Platform+MapKit.swift`|modify|`didSelect`/`didDeselect`, drag, `initInfoWindow`, `updateAnnotation`; drop `wasDragged`; geodesic densify, delete `FlutterGeodesicPolyline`; `handleMapTap(at:flutterApi:in:)`; POI cases, `init?(mkCategory:)`; `PlatformMapFeature.from/make`|
|`lib/src/mk_map_view_controller.dart`, `mk_map_view.dart`|modify|host `dispose`, `initialize` dedupe, sink/adapter events; dispatch order, id assert, `onMapFeatureSelected`, bare drops|
|`lib/src/mk_point_annotation.dart`, `mk_polyline.dart`, `mk_polygon.dart`, `mk_circle.dart`, `cl_location_coordinate_2d.dart`, `camera_conveniences.dart`, `mk_map_snapshot_options.dart`, `mk_enums.dart`, `_internal/map_object_updates.dart`|modify|`onSelect/onDeselect`; sentinel `copyWith`; overlay tap wire flag + `==`; longitude; `fitCoordinates(padding:, minimumSpan:)`; `showsBuildings` doc; `MKMapFeatureType`; `lastById`|
|`lib/src/_internal/unset.dart`, `lib/src/mk_map_feature.dart`; `lib/mapkit_flutter.dart`|create; modify|`unset`; `MKMapFeature`; export|
|`test/_helpers/{fake_host_api,recording_sink}.dart`; `test/{mk_map_view_pre_creation,value_types_regression,duplicate_ids}_test.dart` (create); `test/{mk_map_view,mk_polyline,mk_polygon,mk_circle,camera_conveniences,mk_point_of_interest_filter}_test.dart`|modify / create|`dispose`, sink events; ported repros; new cases|
|`example/ios/**`, `example/macos/**` (incl. `RunnerTests/RunnerTests.swift`), `example/integration_test/{native_leak_test.dart (create),snapshot_test.dart}`, `example/pubspec.yaml`, `example/README.md`|regenerate / modify|SPM projects, XCTests, leak oracle, iOS-only skip, `checks ^0.3.2`, run docs|
|`analysis_options.yaml`, `.pubignore`, `README.md`, `CHANGELOG.md`, `skills/flutter-mapkit-scaffold/` → `skills/mapkit-flutter-scaffold/`|modify / `git mv`|golden lint; accurate ignores; skeleton + docs; `## Unreleased` → `## 0.4.0 - <date>`; skill name/H1/drift|
|`CONTRIBUTING.md`, `.github/{dependabot.yml,ISSUE_TEMPLATE/*,PULL_REQUEST_TEMPLATE.md}`, `.github/workflows/{ci,integration}.yaml`|create / replace / modify|fleet meta; golden CI + MK jobs|
|`.github/workflows/publish.yaml`|create (restore)|deleted tag-publish workflow, tag trigger commented out|

`darwin/…` = `darwin/mapkit_flutter/Sources/mapkit_flutter`; every path is verified against the tree at planning time.

## Phases
Conventions for every phase: run commands from the repo root unless a `cd` is shown; after each phase's oracle passes, tick § Progress, add its CHANGELOG bullets under `## Unreleased` (sections `### Breaking/Added/Changed/Fixed/Removed`, empty ones omitted), then commit via `git-committer`. `RunnerTests` below means `example/macos/RunnerTests/RunnerTests.swift` unless iOS is named. Failing-first: write/port each test, run it, see it fail for the stated reason, then fix.

Native oracle commands (used by several phases; each regenerates the Xcode config first because any `flutter test -d …` leaves `Flutter/ephemeral` pointing at a deleted listener, and a macOS-side regeneration flips the iOS plugin package to `.iOS("15.0")`):

- `MACOS_XCTEST` = `(cd example && flutter build macos --config-only) && xcodebuild test -workspace example/macos/Runner.xcworkspace -scheme Runner -destination 'platform=macOS' -quiet SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`
- `IOS_XCTEST` = `(cd example && flutter build ios --config-only --simulator) && xcodebuild test -workspace example/ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -quiet` (precondition: iOS 17.5 runtime with an `iPhone 15` device — `xcrun simctl list devices available`; first run takes ~10 min, run it in the background)

### Phase 1: Pigeon 29 + SPM foundation
- **IDs**: MK-P1, MK-M2, MK-P6, MK-M7, MK-P2, MK-P7, MK-I2.
- **Files**: `pubspec.yaml`, `pigeons/messages.dart`, generated files, `ios/`, `darwin/mapkit_flutter/Package.swift`, `darwin/.../Utils/MapKitFlutterApi+Send.swift`, the four Swift files with `{ _ in }` call sites, `example/ios/**`, `example/macos/**`, `README.md` (§ Type-safe platform channel), `CHANGELOG.md`.
- **Change**:

|Step|Edit|
|--|--|
|1|`pubspec.yaml`: keep the uncommitted bump, set `pigeon: 29.0.6`; `flutter pub get`.|
|2|`pigeons/messages.dart` lines 1–18 → `// Pigeon schema for the type-safe Dart <-> Swift boundary.` / `//` / `// Regenerate after editing (outputs are checked in; never hand-edit them):` / `//   dart run pigeon --input pigeons/messages.dart` / `//   dart format lib/src/messages.g.dart` / `// CI regenerates and fails on any diff.` / `//` (keep the Naming / Error-code / analyzer notes below). `swiftOut: 'darwin/mapkit_flutter/Sources/mapkit_flutter/messages.g.swift'`.|
|3|Both `@async` in `MapKitHostApi` → `@asyncCallback`, preceded by `// @asyncCallback, not @async: pigeon's async-throws host handlers capture the non-Sendable api/reply in a Task, which Swift 6 rejects.`|
|4|Regenerate (Invariants command); `git rm -r ios`; `dart run build_runner build --delete-conflicting-outputs`.|
|5|Create `Utils/MapKitFlutterApi+Send.swift` (below). Replace every `self.flutterApi.onX(args) { _ in }` / `flutterApi?.onX(args) { _ in }` (`rg -n '\{ _ in \}' darwin` — 18 sites in `AnnotationController.swift`, `TouchHandler.swift`, `FlutterMapView.swift`, `MapKitViewHost.swift`) with `flutterApi.send { try await $0.onX(args) }` (`?.send` where optional); hoist `currentPlatformCamera()`, `PlatformCoordinate.from(…)`, `error.localizedDescription`, overlay `.id` into `let`s first. No-arg calls need `()`: `$0.onCameraIdle()`, `$0.onCameraMoveStarted()`.|
|6|`Package.swift`: add `dependencies: [.package(name: "FlutterFramework", path: "../FlutterFramework")]` and target `dependencies: [.product(name: "FlutterFramework", package: "FlutterFramework")]` (target becomes `.target(name: "mapkit_flutter", dependencies: [...])`).|
|7|Example → SPM: `rm -rf example/ios example/macos && (cd example && flutter create --platforms=ios,macos --org dev.mapkit.flutter --project-name mapkit_flutter_example . && rm test/widget_test.dart)`; `plutil -insert NSLocationWhenInUseUsageDescription -string 'This App needs permission to access your location in order to show it on the map.' example/ios/Runner/Info.plist`; for `example/macos/Runner/{DebugProfile,Release}.entitlements`: `/usr/libexec/PlistBuddy -c 'Add :com.apple.security.network.client bool true' <file>`; `sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/IPHONEOS_DEPLOYMENT_TARGET = 17.0;/' example/ios/Runner.xcodeproj/project.pbxproj`; `sed -i '' 's/MACOSX_DEPLOYMENT_TARGET = 12.0;/MACOSX_DEPLOYMENT_TARGET = 14.0;/' example/macos/Runner.xcodeproj/project.pbxproj`; `grep -c 'DEPLOYMENT_TARGET = 1[47].0;'` must print 3 for each project.|
|8|README § Type-safe platform channel: regenerate = the two-command line from the schema header; outputs `lib/src/messages.g.dart` + `darwin/.../messages.g.swift`; "CI regenerates and fails on drift".|
|9|CHANGELOG: create `## Unreleased` under `# Changelog`. `### Changed`: first bullet `Requires Dart 3.13 / Flutter 3.47 (was Dart 3.10 / Flutter 3.41).`; `Platform channel regenerated with Pigeon 29; host→Dart events use its async Swift API.` `### Removed`: `The hand-patched pigeon deepEquals dictionary branch (dead code — the schema has no Map fields) and the unused ios/ copy of the generated Swift file.` `### Fixed`: `Package.swift declares the FlutterFramework dependency (silences the Flutter 3.47 build warning).`|

```swift
extension MapKitFlutterApi {
    /// Fire-and-forget host -> Dart event. Main-actor tasks start in creation order.
    @MainActor
    func send(_ event: @escaping @MainActor (MapKitFlutterApi) async throws -> Void) {
        Task { @MainActor in try? await event(self) }
    }
}
```
- **Traps**: Switching the two host methods back to `@async` fails in the *generated* `setUp` under Swift 6 — don't hand-patch, keep `@asyncCallback`. Pigeon output is not `dart format`-clean; always format. `flutter create` overwrites `Info.plist` and the entitlements (the location key and `network.client` vanish); `plutil` treats the dots in `com.apple.security.network.client` as a key path, hence PlistBuddy for the entitlements. `flutter create` must not touch `example/lib`, `example/integration_test`, `example/README.md`, `example/test/restyle_lab_test.dart` (check `git status example`). Don't run the example app yet: its geodesic polyline crashes on macOS 27 until Phase 2.
- **Oracle**: `flutter analyze --fatal-infos --fatal-warnings && flutter test && log=$(mktemp) && (cd example && flutter build macos --debug > "$log" 2>&1) && ! grep -qE 'missing a dependency on FlutterFramework|warning: .*mapkit_flutter/Sources' "$log"`

### Phase 2: Native oracle harness, host teardown, geodesic crash
- **IDs**: MK-B1, MK-N1 (planning finding: geodesic subclass memory corruption, see § Invariants).
- **Files**: `pigeons/messages.dart`, generated files, `Utils/ConnectionTrackingMessenger.swift`, `MapKitViewHost.swift`, `FlutterMapView.swift`, `FlutterPolyline.swift`, `lib/src/mk_map_view_controller.dart`, `test/_helpers/fake_host_api.dart`, `example/integration_test/native_leak_test.dart`, `example/integration_test/snapshot_test.dart`, `example/macos/RunnerTests/RunnerTests.swift`.
- **Change**:

|Step|Edit|
|--|--|
|1|Copy `/Users/mehmetesen/pub-dev/sweep-2026-10-03/repros/mapkit_flutter/integration_test/sweep_native_leak_test.dart` → `example/integration_test/native_leak_test.dart`; rename `SWEEP` print prefixes to `leak-oracle`. Run `cd example && flutter test integration_test/native_leak_test.dart -d macos` → red (`Actual: [0, 1, 2]`).|
|2|`snapshot_test.dart`: `import 'dart:io' show Platform;` and `skip: !Platform.isIOS` on its `testWidgets` (compositing is iOS-only; it fails on macOS by design).|
|3|Schema: append to `MapKitHostApi`: `/// Tears down the native view: removes this host's channel handlers, detaches the map delegate, stops location updates.` `void dispose();` Regenerate.|
|4|Create `ConnectionTrackingMessenger.swift` (below). `MapKitViewHost`: delete `var registrar`; add `private let hostMessenger: ConnectionTrackingMessenger`; the public init becomes `public convenience init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64)` calling `self.init(messenger: registrar.messenger(), id: id)` (iOS) / `registrar.messenger` (macOS); new designated `init(messenger: FlutterBinaryMessenger, id: Int64)` with the old body, `self.hostMessenger = ConnectionTrackingMessenger(messenger)`, and `MapKitHostApiSetup.setUp(binaryMessenger: hostMessenger, api: self, messageChannelSuffix: suffix)`. `MapKitFlutterApi` keeps the raw `messenger`.|
|5|`MapKitViewHost.dispose()`: `hostMessenger.removeAllHandlers(); mapView.tearDown(); annotationsById.removeAll(); overlaysById.removeAll(); tileOverlays.removeAll(); currentlySelectedAnnotation = nil`. `FlutterMapView.tearDown()`: `delegate = nil; flutterApi = nil; locationManager.delegate = nil; removeUserLocation(); removeAnnotations(annotations); removeOverlays(overlays)`.|
|6|Dart `MKMapViewControllerImpl.dispose()`: after `MapKitFlutterApi.setUp(null, …)` add `try { await _host.dispose(); } on PlatformException { … }` whose catch body is only the comment `// The native view is already gone; nothing left to release.` `FakeHostApi`: `@override Future<void> dispose() async => _record('dispose', null);`.|
|7|Geodesic: delete `FlutterGeodesicPolyline`; `makeStyledPolyline` returns `FlutterPolyline(fromPlatform: data)`; `FlutterPolyline.init(fromPlatform:)` below.|
|8|`RunnerTests` (macOS) = harness below, plus `ConnectionCountingMessenger` (a `FlutterBinaryMessenger` whose `setMessageHandlerOnChannel` returns an incrementing id kept in `private(set) var live: Set<FlutterBinaryMessengerConnection>` and whose `cleanUpConnection` removes it), private builders `annotation(_:title:callout:)` (marker icon, coordinate 1,2, alpha 1, anchor 0.5/1, draggable, zPriority 500), `configuration(scale:tracking:kind:trackingButton:)` (standard/flat, every flag at the `MKMapView` default, `selectableMapFeatures: []`), `circle(_:zIndex:hidden:)` (center 0,0, radius 50 000, consuming, `.aboveRoads`), and tests `testDisposeRemovesEveryHandler` (`ConnectionCountingMessenger`; host built → `live` non-empty; `try host.dispose()` → `live == []`, `host.mapView.delegate == nil`) and `testGeodesicPolylineIsSafeToStyle` (`makeStyledPolyline` with `isGeodesic: true`, two far coordinates, `lineDashPattern: [6, 3]` → `dashPattern == [6, 3]`, `pointCount > 2`; before the fix the test host crashes).|
|9|CHANGELOG `### Fixed`: `Unmounting a map now releases its native MKMapView, host and location manager (channel handlers were never removed).` `Geodesic polylines no longer corrupt memory on iOS/macOS 27 (MKGeodesicPolyline is no longer subclassed).`|

```swift
/// Forwards to `base` and records every handler connection, so a disposed view can drop its handlers
/// via `cleanUpConnection`. Never `setMessageHandler(nil)`: on macOS the engine stores the nil handler
/// and crashes on the next message to that channel.
final class ConnectionTrackingMessenger: NSObject, FlutterBinaryMessenger {
    private let base: FlutterBinaryMessenger
    private var connections: [FlutterBinaryMessengerConnection] = []
    init(_ base: FlutterBinaryMessenger) { self.base = base }
    func send(onChannel channel: String, message: Data?) { base.send(onChannel: channel, message: message) }
    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
        base.send(onChannel: channel, message: message, binaryReply: callback)
    }
    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection {
        let connection = base.setMessageHandlerOnChannel(channel, binaryMessageHandler: handler)
        connections.append(connection)
        return connection
    }
    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) { base.cleanUpConnection(connection) }
    func removeAllHandlers() {
        connections.forEach(base.cleanUpConnection)
        connections.removeAll()
    }
}
```
(`ConnectionTrackingMessenger.swift` imports `Foundation`, then `#if os(iOS) import Flutter #elseif os(macOS) import FlutterMacOS #endif`.) `FlutterPolyline.init(fromPlatform:)`:
```swift
    convenience init(fromPlatform data: PlatformPolyline) {
        var points = data.coordinates.map(\.clCoordinate)
        if data.isGeodesic, points.count > 1 {
            // Never subclass MKGeodesicPolyline (27 SDKs: its factory init returns the base class).
            let arc = MKGeodesicPolyline(coordinates: points, count: points.count)
            points = UnsafeBufferPointer(start: arc.points(), count: arc.pointCount).map(\.coordinate)
        }
        self.init(coordinates: points, count: points.count)
        applyStyle(fromPlatform: data)
        coordinates = points
    }
```

macOS `RunnerTests` file header: `import Cocoa`, `FlutterMacOS`, `MapKit`, `XCTest`, `@testable import mapkit_flutter`; then `final class RecordingMessenger: NSObject, FlutterBinaryMessenger` — `private(set) var sent: [(channel: String, args: [Any?])]` (args = `MessagesPigeonCodec.shared.decode(message) as? [Any?]`), `send(onChannel:message:binaryReply:)` records and replies `callback?(MessagesPigeonCodec.shared.encode([] as [Any?]))` (pigeon success envelope), `setMessageHandlerOnChannel` returns 0, `cleanUpConnection` no-op, `func args(of method: String) -> [[Any?]]` (channels containing `.<method>.`), `func expectation(for method: String, in test: XCTestCase) -> XCTestExpectation` (sets `assertForOverFulfill = false`, fulfilled by `record` on a matching channel); the `ConnectionCountingMessenger` and builders from step 8; `@MainActor final class RunnerTests: XCTestCase`.

- **Traps**: An async test waiting on `send` must use `RecordingMessenger.expectation(for:in:)` + `await fulfillment(of:timeout: 2)` — sends run in a later main-actor task. `xcodebuild test` after `flutter test -d macos` fails with "listener.dart: No such file" unless the config is regenerated (`MACOS_XCTEST` does it). The leak test must run before `RunnerTests` in the oracle so a crash in either is attributed correctly.
- **Oracle**: `(cd example && flutter test integration_test/native_leak_test.dart -d macos) && MACOS_XCTEST` (expand the alias inline)

### Phase 3: Dart bug fixes
- **IDs**: the table's first column.
- **Files**: `lib/src/mk_map_view.dart`, `mk_map_view_controller.dart`, `_internal/map_object_updates.dart`, `_internal/unset.dart`, `mk_point_annotation.dart`, `mk_polyline.dart`, `mk_polygon.dart`, `mk_circle.dart`, `cl_location_coordinate_2d.dart`, `camera_conveniences.dart`, tests listed in § Files.
- **Change** (repros live in `/Users/mehmetesen/pub-dev/sweep-2026-10-03/repros/mapkit_flutter/`):

|ID|Test first|Fix|
|--|--|--|
|MK-B2|Copy `pre_creation_rebuild_sweep_test.dart` → `test/mk_map_view_pre_creation_test.dart` (import `_helpers/fixtures.dart`); red: `Actual: ['a-old']`.|`didUpdateWidget`: call `_updateDispatchTables()` before `final c = _controller; if (c == null) return;`.|
|MK-B3|`test/duplicate_ids_test.dart`: (1) `pumpWidget(MKMapView(polylines: {red, blue}, debugControllerFactory: …))` → `expect(tester.takeException(), isA<AssertionError>())`; (2) `ControllerHarness().controller.initialize(polylines: {red, blue}, …)` → the recorded `PlatformMapViewCreationParams.polylines` has one entry, `strokeColorArgb == 0xFF0000FF` (red/blue as in the sweep repro).|`map_object_updates.dart`: `@internal List<T> lastById<T>(Iterable<T> objects, String Function(T) idOf) => {for (final o in objects) idOf(o): o}.values.toList();` used by `initialize` for all four sets. `_MKMapViewState`: `bool _debugUniqueIds()` (each set's id count == set length) and `assert(_debugUniqueIds(), 'MKMapView: two objects of one kind share an id')` as the first statement after `super.initState()` (before the post-frame wiring, so a failing widget wires nothing) and after `super.didUpdateWidget(oldWidget)`.|
|MK-B4, MK-B5|Copy `value_types_sweep_test.dart` → `test/value_types_regression_test.dart` (rename `MK-B:` group prefixes to the behaviour); red: 3 tests.|`lib/src/_internal/unset.dart`: `/// copyWith default: "not passed" vs an explicit null.` `@internal const Object unset = Object();`. Every nullable `copyWith` param in `MKPointAnnotation` (`title`, `subtitle`, `clusteringIdentifier`, `onTap`, `onCalloutTap`, `onDragStart`, `onDrag`, `onDragEnd`), `MKPolyline` (`lineDashPattern`, `onTap`), `MKPolygon`/`MKCircle` (`onTap`) → `Object? x = unset` and `x: identical(x, unset) ? this.x : x as T?`. `CLLocationCoordinate2D`: `longitude = (longitude < -180.0 \|\| longitude >= 180.0) ? (longitude + 180.0) % 360.0 - 180.0 : longitude`; class doc adds "in-range values are stored verbatim".|
|MK-I4|In `mk_polyline_test`/`mk_polygon_test`/`mk_circle_test`: `onTap` set + `consumeTapEvents` default → `toPlatform().consumeTapEvents` is true; `copyWith(onTap: null)` of a tappable overlay `!=` the original.|`toPlatform`: `consumeTapEvents: consumeTapEvents \|\| onTap != null`; `==` adds `(other.onTap != null) == (onTap != null)`, `hashCode` adds `onTap != null`. Dartdoc: `onTap` "implies `consumeTapEvents`"; `consumeTapEvents` "also blocks the map's `onTap` without a callback".|
|MK-M5|`camera_conveniences_test`: `padding: 0.1` on the 20°×20° case → span 24; one coordinate → span 0.005.|`fitCoordinates(…, {bool animated = true, double padding = 0, double minimumSpan = 0.005})`: asserts both `>= 0`; span = `max(delta * (1 + 2 * padding), minimumSpan)` clamped to 180 (lat) / 360 (lng), same center.|

- CHANGELOG — `### Fixed`: rebuild-before-creation taps; `copyWith` can clear nullable fields with an explicit `null`; in-range longitudes stored verbatim; `initialize` sends one object per id (duplicates now assert in debug). `### Changed`: `An overlay with onTap now consumes taps (onTap implies consumeTapEvents).`; `fitCoordinates gains padding and minimumSpan; a single coordinate now frames 0.005° instead of zooming fully in.`
- **Traps**: The duplicate-id assert fires in every widget test that builds duplicates — none exist today; keep it that way. `copyWith` casts (`x as String?`) are the only type check left on those params — keep the `T?` in the cast exact. `const Object unset = Object();` is the only allowed sentinel (no `late`). `-0.0` must still equal `0.0` with equal hash (the ported control test covers it).
- **Oracle**: `flutter test`

### Phase 4: Swift bug fixes
- **IDs**: the table's first column.
- **Files**: `AnnotationController.swift`, `FlutterAnnotation.swift`, `TouchHandler.swift`, `FlutterMapView.swift`, `MapKitViewHost.swift`, `PointOfInterestCategory+MapKit.swift`, both `RunnerTests.swift`.
- **Change** (write every test, run the matching oracle red, then fix):

|ID|XCTest (macOS unless iOS)|Fix|
|--|--|--|
|MK-S1|`testCalloutToggleReachesNative`: add `annotation("a")`, change to `callout: true` → `host.annotationsById["a"]?.calloutConsumesTapEvents == true`.|`updateAnnotation`: `oldAnnotation.calloutConsumesTapEvents = annotation.calloutConsumesTapEvents`.|
|MK-S2|`testFirstUpdateAfterDragApplies`: add titled "A"; `host.mapView(host.mapView, annotationView: MKAnnotationView(annotation: …, reuseIdentifier: nil), didChange: .ending, fromOldState: .dragging)`; change title "B" → title is "B".|Delete `FlutterAnnotation.wasDragged`, its `isEqual` line, the `.ending/.canceling` assignment, and the `wasDragged` branch in `annotationsToChange` (keep `if annotationToChange != newAnnotation { updateAnnotation(annotation: newAnnotation) }`).|
|MK-S3|iOS `testEvChargerMapsOnEveryOS`: `XCTAssertEqual(PlatformPointOfInterestCategory.evCharger.mkCategory, .evCharger)` (red only on iOS 17).|`case .evCharger: return .evCharger`; doc on `mkCategory`: "`nil` when the category needs a newer OS than the device runs".|
|MK-S6|`testCalloutOffsetIgnoresViewPosition`: view frame `(300, 120, 40, 40)`; `host.initInfoWindow(annotation:annotationView:)` → `calloutOffset == .zero`.|`initInfoWindow` drops `private`; body starts `annotationView.calloutOffset = .zero` (comment: MapKit centers the callout; `anchorPoint` already moves the view).|
|MK-S7|iOS `testCalloutRecognizerAddedOncePerView`: annotation with `callout: true`; `MKMarkerAnnotationView`; `didSelect` twice → exactly one `InfoWindowTapGestureRecognizer`.|`didSelect` adds the recognizer only if `!(view.gestureRecognizers ?? []).contains(where: { $0 is InfoWindowTapGestureRecognizer })`; new `public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView)`: for a `FlutterAnnotation`, clear `currentlySelectedAnnotation` if it matches, and (iOS) remove every `InfoWindowTapGestureRecognizer` from `view`. Delete `onAnnotationClick(annotation:)` (inline its send).|
|MK-S8|`testHiddenOverlayDoesNotConsumeTap` (hidden consuming circle at 0,0; `TouchHandler.handleMapTap(at: (0,0), flutterApi: host.flutterApi, in: host.mapView)` → `onMapTap` arrives, no `onCircleTap`); `testOnlyTopMostOverlayReceivesTap` (circles "low" zIndex 0 + "high" zIndex 1 → `onCircleTap` args == `[["high"]]`).|`handleMapTaps(tap:flutterApi:in:)` converts the tap and calls new `static func handleMapTap(at coordinate: CLLocationCoordinate2D, flutterApi: MapKitFlutterApi?, in view: MKMapView)`: iterate `view.overlays(in: .aboveLabels).reversed() + view.overlays(in: .aboveRoads).reversed()`; per kind `guard !x.isHidden, x.isConsumingTapEvents, x.contains(…) else { continue }`, send its tap with a hoisted `id`, `return`; after the loop send `onMapTap`. `FlutterMapView.onTap` passes no overlays.|
|MK-S10|`final class CountingMapView: FlutterMapView { var trackingModeSets = 0; override func setUserTrackingMode(_ mode: MKUserTrackingMode, animated: Bool) { trackingModeSets += 1 } }`; `apply(configuration(tracking: .follow))`, then `scale: true` → 1 set; then `tracking: .none` → 2.|`FlutterMapView`: `private(set) var appliedConfiguration: PlatformMapConfiguration?`; `apply` starts `let previousTrackingMode = appliedConfiguration?.userTrackingMode; appliedConfiguration = config` and calls `setUserTrackingMode` only `if config.userTrackingMode != previousTrackingMode` (comment: MapKit drops to `.none` when the user pans; unrelated config changes must not snap back).|
|MK-S13 (tile half; the stuck `selectedProgrammatically` half is deferred → § Found + tracker)|`testReAddingTileOverlayReplacesIt`: `addTileOverlay` twice with `id: ""` → `host.mapView.overlays.count == 1`.|`addTileOverlay`: `if let existing = tileOverlays.removeValue(forKey: overlay.id) { mapView.removeOverlay(existing) }` (no `isEmpty` guard).|
|MK-I5|`testTrackingButtonAppliesOnMacOS`: `apply(configuration(trackingButton: true))` → `showsUserTrackingButton`.|Remove the `#if os(iOS)` around `self.showsUserTrackingButton = …` (macOS 14 has it).|

iOS `example/ios/RunnerTests/RunnerTests.swift`: `import Flutter`, `MapKit`, `UIKit`, `XCTest`, `@testable import mapkit_flutter`; a no-op `FlutterBinaryMessenger` (`setMessageHandlerOnChannel` returns 0); `@MainActor final class RunnerTests: XCTestCase` with the evCharger and callout-recognizer tests (and, in Phase 6, the map-feature tests).

- CHANGELOG `### Fixed`: callout toggle reaches native; first update after a drag no longer dropped; `evCharger` works on iOS 17 (filters no longer hide every POI); custom-image callout no longer offset; `onCalloutTap` fires once per tap; hidden overlays never take taps; tile overlay re-add replaces. `### Changed`: only the top-most consuming overlay receives a tap; `userTrackingMode` is re-applied only when it changes; `showsUserTrackingButton` works on macOS.
- **Traps**: The evCharger test is red only on iOS 17 (`#available(iOS 18.0, *)` is true on macOS) — `IOS_XCTEST` must target OS 17.5. Testable subclassing of `FlutterMapView` needs it to stay non-`final`. `TouchHandler` keeps `@MainActor`.
- **Oracle**: `MACOS_XCTEST && IOS_XCTEST`

### Phase 5: Snapshot fidelity
- **IDs**: MK-S4.
- **Files**: `MapKitViewHost.swift`, `FlutterMapView.swift`, `lib/src/mk_map_snapshot_options.dart`, `RunnerTests`.
- **Change**:

|Step|Edit|
|--|--|
|1|`FlutterMapView`: replace `applyMapConfiguration(_:)` + `poiFilter(from:)` with `nonisolated static func makeMapConfiguration(_ config: PlatformMapConfiguration, hidingPointsOfInterest: Bool = false) -> MKMapConfiguration` (same per-kind body, returning instead of assigning; filter = `hidingPointsOfInterest ? .excludingAll : poiFilter(from:)`) and `private nonisolated static func poiFilter(from:)`. `apply` sets `self.preferredConfiguration = Self.makeMapConfiguration(config)`.|
|2|`MapKitViewHost`: add `struct SnapshotInput: Sendable { var region: MKCoordinateRegion; var size: CGSize; var displayScale: CGFloat; var camera: PlatformMapCamera; var configuration: PlatformMapConfiguration?; var isDark: Bool; var options: PlatformSnapshotOptions }`, `private func snapshotInput(_:)` (iOS: `traitCollection.displayScale`, `.userInterfaceStyle == .dark`; macOS: scale 0, `effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua`; camera `currentPlatformCamera()`, configuration `mapView.appliedConfiguration`), and `nonisolated static func makeSnapshotOptions(_ input: SnapshotInput) -> MKMapSnapshotter.Options` that first reproduces today's options (region, size, iOS `scale`, `showsBuildings`, POI filter). Write `testSnapshotOptionsFollowMapStyleCameraAndAppearance` (input with `configuration(kind: .imagery)`, camera heading 90 / pitch 30, `isDark: true` → `preferredConfiguration is MKImageryMapConfiguration`, `camera.heading == 90 (±0.001)`, `appearance?.name == .darkAqua`); red.|
|3|Final `makeSnapshotOptions` (below). Replace the old `nonisolated static func takeSnapshot(region:…)` with `private nonisolated static func startSnapshot(_ input: SnapshotInput) async throws -> sending MKMapSnapshotter.Snapshot { try await MKMapSnapshotter(options: makeSnapshotOptions(input)).start() }`; the private `takeSnapshot(options:) async throws -> FlutterStandardTypedData?` builds `input`, awaits `startSnapshot`, and keeps the iOS compositing on a local `Options` with only `region`/`size` set.|
|4|`MKMapSnapshotOptions.showsBuildings` dartdoc: "No effect: MapKit no longer supports it; buildings follow the map's configuration."|

```swift
    nonisolated static func makeSnapshotOptions(_ input: SnapshotInput) -> MKMapSnapshotter.Options {
        let options = MKMapSnapshotter.Options()
        options.region = input.region
        options.size = input.size
        options.camera = input.camera.mkCamera
        if let configuration = input.configuration {
            options.preferredConfiguration = FlutterMapView.makeMapConfiguration(
                configuration, hidingPointsOfInterest: !input.options.showsPointsOfInterest)
        }
        #if os(iOS)
        options.traitCollection = UITraitCollection { traits in
            traits.userInterfaceStyle = input.isDark ? .dark : .light
            if input.displayScale > 0 { traits.displayScale = input.displayScale }
        }
        #elseif os(macOS)
        options.appearance = NSAppearance(named: input.isDark ? .darkAqua : .aqua)
        #endif
        return options
    }
```

- CHANGELOG `### Fixed`: `Snapshots now match the on-screen map: style (hybrid/imagery/muted/traffic/elevation/POI filter), rotated/pitched camera and dark mode.` `### Changed`: `MKMapSnapshotOptions.showsBuildings has no effect (MapKit dropped it).`
- **Traps**: Everything crossing into `makeSnapshotOptions` must be a Sendable value — never pass `mapView.camera`/`preferredConfiguration` objects (region isolation rejects sending them); rebuild from `PlatformMapCamera`/`PlatformMapConfiguration`. `UITraitCollection { }` (mutations init) is iOS 17+, matching the floor.
- **Oracle**: `MACOS_XCTEST && (cd example && flutter test integration_test/snapshot_test.dart -d "$(xcrun simctl list devices booted -j | jq -r '[.devices[][]][0].udid')")` (precondition: a booted iOS simulator — `xcrun simctl boot 'iPhone 15'` if none — and network for map tiles; if offline, log the skip in § Found)

### Phase 6: Selection, map-feature and continuous-camera callbacks; iOS 18 POI categories
- **IDs**: MK-G1, MK-G2 (per-annotation `onSelect`/`onDeselect`, continuous `onCameraMove`; the declarative `selectedAnnotationId` part is deferred), MK-G8.
- **Files**: schema, generated files, `AnnotationController.swift`, `MapKitViewHost.swift`, `FlutterMapView.swift`, `PointOfInterestCategory+MapKit.swift`, `Platform+MapKit.swift`, `lib/src/mk_map_feature.dart`, `mk_enums.dart`, `mk_point_annotation.dart`, `mk_map_view.dart`, `mk_map_view_controller.dart`, `lib/mapkit_flutter.dart`, `test/_helpers/recording_sink.dart`, `test/mk_map_view_test.dart`, `test/mk_point_of_interest_filter_test.dart`, both `RunnerTests.swift`.
- **Change**:

|Area|Edit|
|--|--|
|Schema|After `PlatformAnnotationIconType`: `/// MKMapFeatureAnnotation.FeatureType.` `enum PlatformMapFeatureType { pointOfInterest, territory, physicalFeature }`. Before the APIs: `class PlatformMapFeature { PlatformMapFeature({required this.featureType, required this.coordinate, this.title, this.pointOfInterestCategory}); final PlatformMapFeatureType featureType; final PlatformCoordinate coordinate; final String? title; final PlatformPointOfInterestCategory? pointOfInterestCategory; }`. After `zoo,` in `PlatformPointOfInterestCategory`: `// iOS 18 / macOS 15. Dropped from filters on older OS versions.` then `animalService, automotiveRepair, baseball, basketball, beauty, bowling, castle, conventionCenter, distillery, fairground, fishing, fortress, golf, goKart, hiking, kayaking, landmark, mailbox, miniGolf, musicVenue, nationalMonument, planetarium, rockClimbing, rvPark, skatePark, skating, skiing, soccer, spa, surfing, swimming, tennis, volleyball` (one per line). `MapKitFlutterApi` after `onAnnotationTap`: `void onAnnotationSelect(String annotationId);`, `void onAnnotationDeselect(String annotationId);`, `void onMapFeatureSelected(PlatformMapFeature feature);` with one-line docs. Regenerate.|
|POI Swift|One `case .x:` per new category: `if #available(iOS 18.0, macOS 15.0, *) { return .x }` / `return nil`. Add `init?(mkCategory: MKPointOfInterestCategory) { guard let match = Self.allCases.first(where: { $0.mkCategory == mkCategory }) else { return nil }; self = match }` (pigeon 29 enums are `CaseIterable`).|
|Feature Swift|`Platform+MapKit.swift`, `#if os(iOS)`: `extension PlatformMapFeature { static func from(_ feature: MKMapFeatureAnnotation) -> PlatformMapFeature` (= `make(featureType: feature.featureType, coordinate: feature.coordinate, title: (feature as MKAnnotation).title ?? nil, category: feature.pointOfInterestCategory)`) and `static func make(featureType: MKMapFeatureAnnotation.FeatureType, coordinate: CLLocationCoordinate2D, title: String?, category: MKPointOfInterestCategory?) -> PlatformMapFeature` (switch → `.pointOfInterest/.territory/.physicalFeature`, `@unknown default: .pointOfInterest`; category via `flatMap(PlatformPointOfInterestCategory.init(mkCategory:))`).|
|Select Swift|`didSelect`: iOS first `if let feature = view.annotation as? MKMapFeatureAnnotation { let payload = PlatformMapFeature.from(feature); flutterApi.send { try await $0.onMapFeatureSelected(feature: payload) }; return }`; then `guard let annotation = view.annotation as? FlutterAnnotation else { return }`, `let id`, set `currentlySelectedAnnotation`, programmatic flag → else `onAnnotationTap`, then always `onAnnotationSelect(annotationId: id)`, then the iOS recognizer block. `didDeselect` (Phase 4) ends with `onAnnotationDeselect(annotationId: id)`.|
|Camera Swift|`MapKitViewHost`: `public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) { guard self.mapView.bounds.size != .zero else { return }; let camera = self.mapView.currentPlatformCamera(); flutterApi.send { try await $0.onCameraMove(camera: camera) } }`. `FlutterMapView` (iOS): delete the pan/pinch/rotate/tilt recognizers and `onMapGesture`; keep double-tap, long-press, tap. macOS comment: "Camera moves arrive via the delegate."|
|Dart model|`lib/src/mk_map_feature.dart`: `final class const MKMapFeature({required final MKMapFeatureType featureType, required final CLLocationCoordinate2D coordinate, final String? title, final MKPointOfInterestCategory? pointOfInterestCategory})` in the `MKCoordinateSpan` style (`this;`, `@internal factory fromPlatform(PlatformMapFeature p)`, `==`, `hashCode`, `toString`). `mk_enums.dart`: `/// MKMapFeatureAnnotation.FeatureType.` `typedef MKMapFeatureType = PlatformMapFeatureType;`. Barrel exports `src/mk_map_feature.dart`.|
|Dart widget|`MKPointAnnotation`: `final VoidCallback? onSelect, onDeselect` (docs: "`mapView(_:didSelect:)` — user or programmatic, after `onTap`" / "`mapView(_:didDeselect:)`"), not in `==`/`hashCode`, sentinel `copyWith`. `MKMapView`: `final ValueChanged<MKMapFeature>? onMapFeatureSelected` (doc: "iOS only; needs `selectableMapFeatures`"); `onCameraMove` doc: "fires every frame the visible region changes — gestures, momentum and animations, both platforms". `MKMapViewEventSink` + `RecordingSink` + `_MKMapViewFlutterApi` + `_MKMapViewState`: `onAnnotationSelect(MKAnnotationId)`, `onAnnotationDeselect(MKAnnotationId)`, `onMapFeatureSelected(MKMapFeature)` routed like `onAnnotationTap` / `onTap`.|
|Tests|Dart (`mk_map_view_test` inbound events, `created.eventHandler..onAnnotationSelect('a')` style): select/deselect reach the annotation's latest closures; a `PlatformMapFeature` reaches `onMapFeatureSelected` as the equal `MKMapFeature`. `mk_point_of_interest_filter_test`: `MKPointOfInterestCategory.values.length == 73` and `.golf` round-trips `toPlatform`. macOS XCTest `testSelectAndDeselectReachDart` (expectations `onAnnotationSelect`, `onAnnotationDeselect`, `enforceOrder: true`; then `currentlySelectedAnnotation == nil`) and `testVisibleRegionChangeStreamsCamera` (frame 200×200, `try await Task.sleep(for: .milliseconds(200))`, `before` = `onCameraMove` count, call `mapViewDidChangeVisibleRegion`, await → count == `before + 1`). iOS `testMapFeaturePayloadMapsTypeAndCategory` (`make(.territory, …, "Cupertino", .evCharger)` → fields mapped) and `testIOS18CategoryDroppedBeforeIOS18` (`.golf.mkCategory` is `.golf` under `#available(iOS 18.0, *)`, else nil).|

- CHANGELOG `### Added`: `MKPointAnnotation.onSelect / onDeselect.`; `MKMapView.onMapFeatureSelected (iOS) with MKMapFeature / MKMapFeatureType.`; `33 iOS 18 / macOS 15 MKPointOfInterestCategory values (ignored by filters on older OS versions).` `### Changed`: `onCameraMove fires continuously (gestures, momentum, animations) on iOS and macOS via mapViewDidChangeVisibleRegion.` `### Breaking`: `MKPointOfInterestCategory gained 33 values — exhaustive switches over it must handle them.`
- **Traps**: Do not implement the iOS-16 `didSelect annotation:` delegate variant alongside the view variant. An `including([...])` filter whose every category is unavailable on the running OS shows no POIs — documented, not a bug. `RecordingSink` must implement the three new sink methods or every test file fails to compile.
- **Oracle**: `flutter test && MACOS_XCTEST && IOS_XCTEST`

### Phase 7: Packaging
- **IDs**: MK-P3, MK-P5, X-13, X-16.
- **Files**: `darwin/mapkit_flutter.podspec`, `Package.swift`, `PrivacyInfo.xcprivacy`, `.pubignore`.
- **Change**: podspec — delete the `'OTHER_SWIFT_FLAGS' => '-warnings-as-errors'` entry (and the trailing comma on `'SWIFT_VERSION'`); add `s.resource_bundles = {'mapkit_flutter_privacy' => ['mapkit_flutter/Sources/mapkit_flutter/PrivacyInfo.xcprivacy']}`; `s.description` "look-around (iOS only)" stays. `Package.swift` target gains `resources: [.process("PrivacyInfo.xcprivacy")]`. `PrivacyInfo.xcprivacy` = plist dict `NSPrivacyTracking` false, `NSPrivacyTrackingDomains` [], `NSPrivacyCollectedDataTypes` [], `NSPrivacyAccessedAPITypes` [] (`plutil -lint` clean). `.pubignore` becomes: header `# pub reads this file instead of .gitignore in this directory, so it repeats` / `# every root ignore that matters for the published archive.`, then `*.log`, `*.iml`, `**/doc/api/`, `build/`, `coverage/`, `pubspec.lock`, `plans/`, `example/build/`, `example/ios/Flutter/ephemeral/`, `example/macos/Flutter/ephemeral/`.
- CHANGELOG `### Added`: `Apple privacy manifest (PrivacyInfo.xcprivacy) for SPM and CocoaPods.` `### Fixed`: `The podspec no longer forces -warnings-as-errors on CocoaPods consumers.`
- **Traps**: The podspec cannot be exercised locally (no CocoaPods); Phase 10's `cocoapods-probe` job is its oracle. Dry-run output lists the tree with `│`/`├──` prefixes; the top-level `ios` row would read `├── ios`.
- **Oracle**: `(cd example && flutter build macos --debug && find build/macos -path '*.app/Contents/Resources/mapkit_flutter_mapkit_flutter.bundle/*' -name PrivacyInfo.xcprivacy | grep -q .) && log=$(mktemp) && { flutter pub publish --dry-run > "$log" 2>&1; true; } && grep -q 'PrivacyInfo.xcprivacy' "$log" && ! grep -qE '^├── ios|Podfile' "$log"`

### Phase 8: Repo meta, lint config, pubspec
- **IDs**: X-1, X-2, X-17, X-18.
- **Files**: `pubspec.yaml`, `example/pubspec.yaml`, `analysis_options.yaml`, `lib/src/mk_map_view.dart`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*`, `.github/dependabot.yml`.
- **Change**:

|File|Edit|
|--|--|
|`pubspec.yaml`|Delete `homepage:` and `documentation:` lines (order is then name, description, version, repository, issue_tracker, topics, environment, dependencies, dev_dependencies, flutter).|
|`example/pubspec.yaml`|`checks: ^0.3.2`.|
|`analysis_options.yaml`|`mkdir -p .dart_tool && touch .dart_tool/.config-edit-ok`, write the block below, `rm .dart_tool/.config-edit-ok` immediately (a PreToolUse hook blocks this file otherwise; never use the marker for anything else).|
|`lib/src/mk_map_view.dart`|Each `unawaited(<expr>)` (7 sites: `dispose`, `_wireController`, five `_update*`) → bare `<expr>;`; drop `import 'dart:async';`. `rg -n 'unawaited\(' lib test example` must print nothing.|
|meta files|Exactly the blocks below.|

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - build/**
    - "**/*.g.dart"
    - "**/*.mocks.dart"

linter:
  rules:
    # Maintainer convention: fire-and-forget is a bare drop; never unawaited().
    unawaited_futures: false
    discarded_futures: false
```

No `SECURITY.md`: the maintainer accepts no private vulnerability reports.

`CONTRIBUTING.md`:
```markdown
# Contributing

1. `flutter pub get`
2. Run what CI runs:
   - `git ls-files -z -- '*.dart' | xargs -0 dart format --output=none --set-exit-if-changed`
   - `flutter analyze --fatal-infos --fatal-warnings`
   - `flutter test`
   - `flutter pub publish --dry-run`
3. Add a line under `## Unreleased` in `CHANGELOG.md` for every user-visible change.

Releases are published manually by the maintainer.
```

`.github/PULL_REQUEST_TEMPLATE.md` (replaces the current file):
```markdown
## Summary

## Checklist

- [ ] Tests added or updated
- [ ] `CHANGELOG.md` `## Unreleased` entry
- [ ] Docs / README / skill updated if public API changed
```

`.github/ISSUE_TEMPLATE/bug_report.yaml`:
```yaml
name: Bug report
description: Something is broken in mapkit_flutter
title: "[bug] "
labels: [bug]
body:
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: A clear, concise description of the bug.
      placeholder: |
        Describe what you did and what went wrong.
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: Minimal reproduction
      description: A minimal Dart snippet that reproduces the issue.
      render: dart
      placeholder: |
        // minimal reproduction
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
    validations:
      required: true
  - type: input
    id: package-version
    attributes:
      label: mapkit_flutter version
      placeholder: 0.4.0
    validations:
      required: true
  - type: textarea
    id: env
    attributes:
      label: Environment
      description: Output of `flutter doctor -v`.
      render: shell
    validations:
      required: true
```

`.github/ISSUE_TEMPLATE/feature_request.yaml`:
```yaml
name: Feature request
description: Suggest a new capability or improvement
title: "[feature] "
labels: [enhancement]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem
      description: What problem are you trying to solve?
    validations:
      required: true
  - type: textarea
    id: proposed
    attributes:
      label: Proposed solution
      description: How would you like this to work?
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
    validations:
      required: false
```

`.github/ISSUE_TEMPLATE/config.yml`:
```yaml
blank_issues_enabled: true
```

`.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: pub
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
    labels: [dependencies]
  - package-ecosystem: pub
    directory: /example
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
    labels: [dependencies, example]
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    labels: [dependencies, ci]
```

- **Traps**: Excluding `**/*.g.dart` does not stop the analyzer resolving `messages.g.dart` — it only silences its lints. `discarded_futures: false` is what makes the bare `_controller?.dispose();` legal.
- **Oracle**: `flutter analyze --fatal-infos --fatal-warnings && (cd example && flutter analyze --fatal-infos --fatal-warnings) && git ls-files -z -- '*.dart' | xargs -0 dart format --output=none --set-exit-if-changed && flutter test && ! rg -n 'unawaited\(' lib test example && yq '.' .github/dependabot.yml .github/ISSUE_TEMPLATE/*.y*ml > /dev/null`

### Phase 9: Docs and agent skill
- **IDs**: MK-I1, MK-I3, MK-I6, MK-I7, MK-P4, MK-M6, X-5, X-11, X-19.
- **Files**: `README.md`, `example/README.md`, `CHANGELOG.md`, `skills/mapkit-flutter-scaffold/SKILL.md`, dartdoc in `mk_map_view.dart`, `mk_point_annotation.dart`, `mk_map_snapshot_options.dart`.
- **Change**:

|Target|Edit|
|--|--|
|README top|`# mapkit_flutter`, then one badge row: `[![pub package](https://img.shields.io/pub/v/mapkit_flutter.svg)](https://pub.dev/packages/mapkit_flutter) [![pub points](https://img.shields.io/pub/points/mapkit_flutter)](https://pub.dev/packages/mapkit_flutter/score) [![CI](https://github.com/esenmx/mapkit_flutter/actions/workflows/ci.yaml/badge.svg)](https://github.com/esenmx/mapkit_flutter/actions/workflows/ci.yaml) [![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)`; pitch = current lines 5–9 with the blockquote's last sentence → "Look Around is presented on iOS; on macOS `openLookAround` returns `false` (not wired yet)."|
|README `## Install`|Only the `flutter pub add mapkit_flutter` block.|
|README `## Platform setup` (new, after Install)|Deployment targets: iOS 17.0 (`IPHONEOS_DEPLOYMENT_TARGET` on the Runner target, or Podfile `platform :ios, '17.0'`), macOS 14.0 (`MACOSX_DEPLOYMENT_TARGET`, or `platform :osx, '14.0'`) — an SPM app on Flutter's default 12.0 fails with "requires minimum platform version 14.0". Move the `NSLocationWhenInUseUsageDescription` block here. Requirements table keeps iOS / macOS / Xcode rows; the "Flutter / Dart" row is removed.|
|README `## Platform differences` (new, after Platform setup)|Table iOS vs macOS: `onCalloutTap` ✓/✗ (default callout); image-icon `anchorPoint` ✓/✗ (centered); `followWithHeading` ✓/falls back to `follow`; snapshot annotation/overlay compositing ✓/✗ (base map only); `selectableMapFeatures` + `onMapFeatureSelected` ✓/✗; `openLookAround` ✓/returns `false`; `showsUserTrackingButton` ✓/✓; `onCameraMove` continuous on both; `onDrag` reports drag-state changes, not every movement, on both.|
|README usage|Annotations: add `onSelect`/`onDeselect` to the callout+drag example; MKMapView: `selectableMapFeatures: {MKMapFeatureOptions.pointsOfInterest}, onMapFeatureSelected: (feature) => debugPrint('${feature.title}')`; Overlays: one sentence "`onTap` implies `consumeTapEvents`; only the top-most overlay under a tap fires"; after Overlays: "Models override `==`, so they can't be used in `const {…}` set literals — build the set without `const`."; `copyWith(title: null)` clears a field; `fitCoordinates(…, padding: 0.1)`.|
|README end|Replace `## Claude Code skill` with the fleet block (below), then `## Contributing` — "See [CONTRIBUTING.md](CONTRIBUTING.md)." — then the existing `## License`.|
|Skill|`git mv skills/flutter-mapkit-scaffold skills/mapkit-flutter-scaffold`; frontmatter `name: mapkit-flutter-scaffold`, keep `description` and `disable-model-invocation: true`; H1 `# mapkit-flutter-scaffold`. Line 16: Look Around "presented on iOS; `false` on macOS"; add "`onSelect`/`onDeselect` per annotation; `onMapFeatureSelected` (iOS, needs `selectableMapFeatures`); `onCameraMove` is continuous; `copyWith(x: null)` clears". Line 18 → "Tap callbacks: `MKPointAnnotation.onTap` / `onCalloutTap` (iOS); overlays' `onTap` implies `consumeTapEvents`, and only the top-most visible overlay fires." Line 19: "`selectableMapFeatures` is iOS-only (ignored on macOS)"; `showsUserTrackingButton` works on both.|
|Old-name sweep|`rg -n 'flutter-mapkit-scaffold'` → only the CHANGELOG 0.3.2 line remains; rewrite it to `skills/mapkit-flutter-scaffold/SKILL.md` (drops the stale `tool/` prefix too). Then `rg` prints nothing.|
|dartdoc|`MKMapView.showsUserTrackingButton`: "iOS 17 / macOS 14"; `MKMapView.selectableMapFeatures`: "iOS only"; `MKPointAnnotation.onCalloutTap` and `anchorPoint`: "iOS only"; `MKMapSnapshotOptions.showsAnnotations/showsOverlays`: "iOS only; macOS snapshots contain the base map".|
|`example/README.md`|"Run it on an iOS simulator or macOS (`flutter run -d macos`)." Integration: `flutter test integration_test/<file>.dart -d macos` (one file per invocation) and on a simulator; native tests: `flutter build macos --config-only && xcodebuild test -workspace macos/Runner.xcworkspace -scheme Runner -destination 'platform=macOS'`.|
|CHANGELOG|`### Breaking`: `The agent skill moved to skills/mapkit-flutter-scaffold/ (dart run skills@ get requires the package-name prefix).` `### Changed`: `Docs: Look Around and showsUserTrackingButton platform notes corrected; per-platform differences table; deployment-target setup.`|

README agent-skill block (verbatim):
````markdown
## Agent skill

This package ships an agent skill in `skills/mapkit-flutter-scaffold/`. Install it into your project's agent config with:

```sh
dart run skills@ get --package mapkit_flutter --all
```
````

Snippet check: copy `/Users/mehmetesen/pub-dev/sweep-2026-10-03/repros/mapkit_flutter/docs_snippets_scratch.dart` to `example/lib/readme_snippets_scratch.dart`, re-transcribe every changed README/SKILL snippet into it, `cd example && flutter analyze lib/readme_snippets_scratch.dart` must report no errors or warnings, then delete the file (never commit it).

- **Traps**: `LICENSE` stays "2026" — the first publish (0.1.0) was 2026-06-12. Never `dart run skills@ get mapkit_flutter --all` (the positional is ignored with `--all` and installs every dependency's skills). A fresh probe has no agent markers, so the oracle passes `--agent claude`.
- **Oracle**: `tmp=$(mktemp -d) && cd $tmp && flutter create -t app probe && cd probe && flutter pub add mapkit_flutter --path /Users/mehmetesen/pub-dev/mapkit_flutter && dart run skills@ get --package mapkit_flutter --agent claude --all 2>&1 | tee $tmp/skills_get.txt && ! grep -q 'Skipping skill' $tmp/skills_get.txt && find . -path '*mapkit-flutter-scaffold/SKILL.md' | grep -q .` (if `skills@` can't resolve offline: § Found, and fall back to `ls skills | grep -qx 'mapkit-flutter-scaffold'`)

### Phase 10: CI
- **IDs**: MK-P8, X-6, X-9, X-10, X-12.
- **Files**: `.github/workflows/ci.yaml` (replace), `.github/workflows/integration.yaml` (modify), `.github/workflows/publish.yaml` (restore).
- **Change**: `ci.yaml` = the fleet golden (format, analyze, test floor/stable/beta, downgrade, pana, publish-dry-run) with the current podspec guard as `analyze`'s first step, plus `codegen`, `example-apple` (keeps the iOS and macOS example builds, adds native XCTest and macOS integration) and `cocoapods-probe`. The coverage artifact upload is gone. `git -C ~/Sdk/flutter tag | grep -x 3.47.0` must print `3.47.0` (verified at planning).
```yaml
name: CI

on:
  push:
    branches: [master]
  pull_request:
    branches: [master]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  format:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: git ls-files -z -- '*.dart' | xargs -0 dart format --output=none --set-exit-if-changed
  analyze:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - name: Check podspec version matches pubspec
        run: |
          pubspec_version=$(grep -m1 '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//')
          status=0
          found=0
          while IFS= read -r podspec; do
            found=$((found+1))
            podspec_version=$(grep -m1 "s\.version" "$podspec" | sed -E "s/.*s\.version[[:space:]]*=[[:space:]]*'([^']+)'.*/\1/")
            if [ "$podspec_version" != "$pubspec_version" ]; then
              echo "::error file=$podspec::podspec version ($podspec_version) does not match pubspec.yaml version ($pubspec_version)"
              status=1
            fi
          done < <(find . -name '*.podspec' -not -path './example/*' -not -path './build/*')
          if [ "$found" -eq 0 ]; then
            echo "::error::no podspec found — guard is vacuous, update the find paths"
            status=1
          fi
          exit $status
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter analyze --fatal-infos --fatal-warnings
      - run: flutter pub get
        working-directory: example
      - run: flutter analyze --fatal-infos --fatal-warnings
        working-directory: example
  test:
    name: test (${{ matrix.name }})
    runs-on: ubuntu-latest
    timeout-minutes: 20
    strategy:
      fail-fast: false
      matrix:
        include:
          - { name: floor, channel: stable, version: '3.47.0' }
          - { name: stable, channel: stable, version: '' }
          - { name: beta, channel: beta, version: '' }
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with:
          channel: ${{ matrix.channel }}
          flutter-version: ${{ matrix.version }}
          cache: true
      - run: flutter pub get
      - run: flutter test
  downgrade:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub downgrade
      - run: flutter analyze --fatal-warnings
      - run: flutter test
  pana:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: dart pub global activate pana
      - run: dart pub global run pana --no-warning --exit-code-threshold 0
  publish-dry-run:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub publish --dry-run
  codegen:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - run: dart run pigeon --input pigeons/messages.dart && dart format lib/src/messages.g.dart
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: git diff --exit-code
  example-apple:
    name: example (iOS + macOS builds, native tests, macOS integration)
    runs-on: macos-15
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter config --enable-swift-package-manager
      - run: flutter config --enable-macos-desktop
      - working-directory: example
        run: |
          set -e
          flutter build ios --release --no-codesign
          flutter build macos --debug
          xcodebuild test -workspace macos/Runner.xcworkspace -scheme Runner -destination 'platform=macOS' -quiet SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
          for test in integration_test/*_test.dart; do flutter test "$test" -d macos; done
  cocoapods-probe:
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter config --no-enable-swift-package-manager
      - name: Build a CocoaPods app against the podspec
        run: |
          set -e
          flutter create --platforms=ios "$RUNNER_TEMP/cp_probe"
          cd "$RUNNER_TEMP/cp_probe"
          sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = 17.0;/' ios/Runner.xcodeproj/project.pbxproj
          flutter pub add mapkit_flutter --path "$GITHUB_WORKSPACE"
          flutter build ios --debug --simulator
```

`integration.yaml`: comment out the tag trigger instead of deleting it — replace the line `    tags: ['v*']` with `    # tags: ['v*']  # paused with tag-triggered publishing; uncomment to re-enable`; add top-level `permissions:` / `  contents: read` after `on:`; `actions/checkout@v6` → `@v7`; insert `- run: flutter config --enable-swift-package-manager` before the `flutter pub get` step; keep the iOS runner script unchanged; append job `native-ios` (`runs-on: macos-15`, `timeout-minutes: 45`; steps: `actions/checkout@v7`, `subosito/flutter-action@v2` with `{ channel: stable, cache: true }`, `flutter config --enable-swift-package-manager`, `flutter build ios --config-only --simulator` in `example`, then `xcodebuild test -workspace example/ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`).


Restore `.github/workflows/publish.yaml` (deleted in commit `d0d04f5`) with its tag trigger commented out — automated publishing stays configured on pub.dev for later; `workflow_dispatch` keeps it a valid workflow and a manual run cannot publish (pub.dev requires a tag push; `verify` also fails off a tag):
```yaml
name: Publish

on:
  # Automated publishing is paused; pub.dev Admin → Automated publishing stays enabled.
  # Re-enable by uncommenting the tag trigger below. pub.dev rejects publishes not started
  # by a tag push, so a manual workflow_dispatch run cannot publish.
  # push:
  #   tags:
  #     - 'v[0-9]+.[0-9]+.[0-9]+*'
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  verify:
    name: Verify tag, formatting, and analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - name: Check tag matches pubspec version
        run: |
          TAG="${GITHUB_REF#refs/tags/v}"
          PUBSPEC=$(grep '^version:' pubspec.yaml | awk '{print $2}')
          if [ "$TAG" != "$PUBSPEC" ]; then
            echo "::error::Tag v$TAG does not match pubspec.yaml version $PUBSPEC"
            exit 1
          fi
      - run: flutter pub get
      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .
      - name: Verify analysis
        run: flutter analyze --fatal-infos --fatal-warnings

  publish:
    name: Publish to pub.dev
    needs: verify
    runs-on: ubuntu-latest
    environment: pub.dev
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v6
      - uses: dart-lang/setup-dart@v1
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter pub publish --force
```
- **Traps**: The `analyze` guard step body above is the pre-plan guard verbatim; keep it byte-identical (it fails when no podspec matches, so it is never vacuous). Never write a flow mapping containing `${{ }}` (invalid YAML) — only the matrix `with:` uses expressions and it is block form. CI-only failures are found in Phase 11: a red `cocoapods-probe` caused by the podspec is fixed in code; one caused by runner tooling gets `continue-on-error: true` on that job only, plus § Found and a tracker row. If `pana` fails *after* printing 160/160 with `PathNotFoundException`, same treatment for `pana`.
- **Oracle**: `yq '.' .github/workflows/ci.yaml .github/workflows/integration.yaml > /dev/null && [ "$(yq '.jobs | keys | length' .github/workflows/ci.yaml)" -eq 9 ] && ! grep -qE '^[[:space:]]*tags:' .github/workflows/integration.yaml && grep -qE "^[[:space:]]*# tags: \['v\*'\]" .github/workflows/integration.yaml && yq -e '(.on | has("workflow_dispatch")) and (.on | has("push") | not)' .github/workflows/publish.yaml && grep -q 'contents: read' .github/workflows/integration.yaml && grep -q 'podspec_version' .github/workflows/ci.yaml`

### Phase 11: Release 0.4.0
- **IDs**: X-7, X-8.
- **Files**: `pubspec.yaml`, `darwin/mapkit_flutter.podspec`, `CHANGELOG.md`, `plans/sweep-fixes.md`, `/Users/mehmetesen/pub-dev/SWEEP.md`.
- **Change**:

|Step|Action|
|--|--|
|1|`pubspec.yaml` `version: 0.4.0`; podspec `s.version = '0.4.0'`. CHANGELOG `## Unreleased` → `## 0.4.0 - <YYYY-MM-DD of this commit>`; sections in order Breaking, Added, Changed, Fixed, Removed; `### Changed` starts with the "Requires Dart 3.13 / Flutter 3.47" bullet. Backfill: none needed — every published version (0.1.0–0.3.7, `curl -s https://pub.dev/api/packages/mapkit_flutter \| jq -r '.versions[].version'`) has a heading and no unpublished heading exists; title already `# Changelog`.|
|2|Commit (release commit includes the plan's current ticks), then run every § Verification step on the clean tree.|
|3|Append one bullet per deferred item to `/Users/mehmetesen/pub-dev/SWEEP.md` `## Deferred`, format `- [mapkit_flutter] <ID> — <one line> — <why deferred>`: every ID in § Out of scope "Deferred", the two deferred halves named in Phases 4 and 6, and anything § Found left open.|
|4|`git rm plans/sweep-fixes.md`; commit via `git-committer` (`chore: release 0.4.0 prep — remove executed plan`); `git push origin master`.|
|5|`gh run watch --exit-status $(gh run list -L1 --workflow ci.yaml --json databaseId -q '.[0].databaseId') && gh run watch --exit-status $(gh run list -L1 --workflow integration.yaml --json databaseId -q '.[0].databaseId')`; on red: fix, commit, push, re-watch (Phase 10 traps decide `continue-on-error`).|

- **Traps**: Run Verification only after the release commit — `pub publish --dry-run` exits 65 on any modified tracked file. Never `dart pub publish`, tag, or create a release.
- **Oracle**: step 5's command exits 0.

## Verification
Run in order on the committed tree (Phase 11 step 2):

1. `git ls-files -z -- '*.dart' | xargs -0 dart format --output=none --set-exit-if-changed && flutter analyze --fatal-infos --fatal-warnings && (cd example && flutter analyze --fatal-infos --fatal-warnings) && flutter test`
2. `dart run pigeon --input pigeons/messages.dart && dart format lib/src/messages.g.dart && dart run build_runner build --delete-conflicting-outputs && git diff --exit-code`
3. `flutter pub publish --dry-run` (exit 0, "Package has 0 warnings")
4. `(cd example && flutter build macos --debug && flutter build ios --release --no-codesign)` then `MACOS_XCTEST` (Phases alias)
5. `(cd example && for t in integration_test/*_test.dart; do flutter test "$t" -d macos || exit 1; done)`
6. `IOS_XCTEST` (precondition: iOS 17.5 runtime + `iPhone 15`; a missing runtime is a skip → § Found, plan stays `in-progress`)
7. `(cd example && flutter test integration_test/snapshot_test.dart -d <booted iOS simulator udid>)` (precondition: network for map tiles)
8. Skills oracle from Phase 9.

## Edge cases
- **Dispose races**: queued calls see `_disposed` → `MapKitDisposedException`; one in flight is answered before `dispose` (channel order); `dispose` on an already-gone view throws `PlatformException` → swallowed. Unmount before creation wires nothing.
- **After dispose**: handlers are gone (`cleanUpConnection`), so a late Dart call gets `channel-error`; delegate and `flutterApi` are nil, so no events follow. Hot restart never calls `dispose` (unchanged).
- **Degenerate input**: geodesic with < 2 points is not densified; snapshot before `initialize` uses MapKit's default style; zero bounds skip `onCameraMove`; an all-unavailable `including` POI filter shows no POIs.
- **Selection**: clusters and map features are not `FlutterAnnotation`s → no `onSelect`/`onDeselect`; features go to `onMapFeatureSelected` (iOS).
- **Release builds**: the duplicate-id assert is stripped; last object per id wins in `initialize` and the diff. `copyWith(title: 42)` compiles and throws `TypeError` at runtime.

## Out of scope
Deferred (append to the tracker in Phase 11):

|ID|Why deferred|
|--|--|
|MK-S5|`openLookAround` hang on a rejected presentation: no failing-first oracle (needs a live Look Around scene and a double-modal presenter).|
|MK-S9|Continuous `onDrag`: MapKit sets the coordinate only on drop; needs view-position tracking, no oracle (documented in the platform table).|
|MK-S11|Map `onTap` on annotation taps / macOS double-click: needs hit-testing of laid-out annotation views; no headless oracle.|
|MK-S12|Snapshot holes and gradient strokes: renderer-based redraw with an iOS-simulator pixel oracle; the geodesic straight-line sub-item is fixed incidentally by the Phase 2 densify.|
|MK-G3, MK-G4, MK-G5, MK-G6, MK-G7, MK-G9, MK-G10, MK-G11, MK-G12, MK-G13, MK-G14|Features not in the sweep's MK feature list.|
|MK-M1|Read-skips-queue + timeouts changes the documented source-order contract; not small.|
|MK-M3|A cached hash needs a mutable/`late` field, impossible with const constructors and the no-`late final` rule; `listEquals` already short-circuits `identical`.|
|MK-M4|Initial camera via creation params touches platform-view creation on both platforms; no oracle can observe the flash.|

Not applicable here: X-3, X-4, X-14, X-20. Also out: class modifiers, public renames, removing `consumeTapEvents` or `MKMapSnapshotOptions.showsBuildings`, `example/lib` feature demos, the iOS 27 POI categories, branch renames.

User-only steps (the executor never does these): publish the release to pub.dev (pub.dev Admin → Automated publishing stays enabled; the restored `publish.yaml` keeps its tag trigger commented out until you re-enable it). Optional: a DNS record for mehmetesen.com before re-adding `homepage:`.

## Found
Tracker: `/Users/mehmetesen/pub-dev/SWEEP.md` § Deferred (`- [mapkit_flutter] <ID> — <one line> — <why deferred>`).

Executor appends one bullet per discovery the plan didn't name: blocking and in-scope → fix + note; else note only, never silently absorbed. A log, not a tracker — it is deleted with the plan: anything left open — skipped check, deferred follow-up, user-only step — also gets a tracker row (`none` → final report); a finding stays open until its check runs.

- Phase 1: a full `flutter build ios --simulator` right after a macOS build failed once with "package product 'mapkit-flutter-product' requires minimum platform version 17.0 … but this target supports 15.0" (the iOS `FlutterGeneratedPluginSwiftPackage` still said `.iOS("15.0")`); `flutter build ios --config-only --simulator` rewrote it to 17.0 and the next full build passed. The `IOS_XCTEST` alias already regenerates first; for Verification step 4 run the iOS config step before `flutter build ios` if it trips. Closed (workaround known).
- Phase 1/2: the first `flutter build` of each regenerated example adds `FlutterFramework` and `mapkit_flutter` `PBXFileReference`s to its `project.pbxproj`; committed (macOS in Phase 1, iOS in Phase 2) so later builds leave the tree clean. Closed.
- Phase 1: 16 `{ _ in }` call sites, not 18; `rg '\{ _ in \}' darwin` prints nothing. Closed.
- Phase 3 (deviation; superseded by R-MK-2 below, the `List<num>` workaround is reverted): the sentinel `copyWith` broke an existing call at runtime. With an `Object?` parameter, `copyWith(lineDashPattern: [6, 3])` / `const [1]` (`test/mk_polyline_test.dart:103`) infers `List<int>`, so the exact `as List<double>?` cast threw `TypeError`, contradicting the Decision's "source-compatible for every existing call". `MKPolyline.copyWith` now casts `lineDashPattern as List<num>?` and maps `toDouble()`; a non-numeric list still throws. String literals cast fine, but closure literals are affected too (correction from review): in an `Object?` context `copyWith(onDragEnd: (c) => last = c)` loses parameter inference, so `c` is `dynamic` and `strict-casts` reports `invalid_assignment` (3 errors in the reviewer's probe; no such call exists in the repo). Declined at the time: keep the exact cast, change the test to `<double>[1]` and document the runtime trap. Closed by R-MK-2.
- Phase 4: MK-S13's other half (an annotation whose programmatic `showCallout` never produced a `didSelect` keeps `selectedProgrammatically == true`, so its next user tap is swallowed) is deferred per the plan. Tracker row appended in Phase 4; Phase 11 step 3 must not add it again. Open.
- Phase 5: the oracle's `xcrun simctl list devices booted … [0].udid` picks whichever simulator boots first; another executor had an iOS 27 `iPhone 16 Pro` booted, so the snapshot test ran on the explicit `iPhone 15` (iOS 17.5) UDID `E1C2FC5C-7A36-484B-A573-CC5E580C3C63`. Use an explicit UDID for Verification step 7 too, and boot it first: between runs the base `iPhone 15` was found shut down ("No supported devices found"); re-booted and re-ran. Closed.
- Phase 6 (fix of the Phase 5 snippet): `UITraitCollection { traits in … }` in the nonisolated `makeSnapshotOptions` emits two Swift 6 warnings on the iOS 27 SDK ("main actor-isolated property 'userInterfaceStyle' / 'displayScale' can not be mutated from a nonisolated context": `UIMutableTraits` is `NS_SWIFT_UI_ACTOR`). The macOS-only warnings-as-errors build cannot see it. Replaced with `UITraitCollection(userInterfaceStyle:)` + `replacing(UITraitDisplayScale.self, value:)` (iOS 17 API, not deprecated); iOS build has 0 warnings, snapshot integration test re-run. CI never builds iOS with `SWIFT_TREAT_WARNINGS_AS_ERRORS`, so a regression there stays invisible; noted, not changed. Closed.
- Phase 6: the native select/camera tests were red on behaviour (`onAnnotationSelect`/`onAnnotationDeselect` and `onCameraMove` expectations timed out); the camera test calls the delegate method as MapKit does (`(host as MKMapViewDelegate).mapViewDidChangeVisibleRegion?(…)`), so it compiled before the method existed. The iOS feature-payload test was red at compile time (`PlatformMapFeature has no member 'make'`); `testIOS18CategoryDroppedBeforeIOS18` cannot be red without contortion (the plugin doesn't compile until every new enum case is handled). The `MapKitViewHost.regionDidChangeAnimated` still sends one `onCameraMove` before `onCameraIdle`, now a duplicate of the last continuous move; the plan didn't remove it, kept. Closed.
- Phase 9: the old-name sweep `rg -n 'flutter-mapkit-scaffold'` still matches this plan file (deleted in Phase 11); outside `plans/` it prints nothing. The snippet scratch gained `unused_field` in its own `ignore_for_file`: the verbatim, unchanged README Quick start assigns `_controller` without reading it (intentionally partial snippet, not drift). Closed.
- Pre-release local § Verification (after Phase 10, on 348b776, clean tree): steps 1–8 all passed. Step 3 printed `Package has 0 warnings`. Step 4's `flutter build ios --release --no-codesign` after the macOS build passed without the Phase 1 manifest trip. Step 5: on the first run `home_page_test.dart` hung on macOS after "Failed to foreground app; open returned 1" (no output for 14 minutes; killed). The re-run passed in 14 s; the remaining files passed and `snapshot_test` was skipped as designed. Step 6: `xcodebuild` could not clone `iPhone 15` ("Device was allocated but was stuck in creation state", three attempts; other executors were cloning the same device). The same tests passed on the same device and OS (iPhone 15, iOS 17.5, 4/4) with `-parallel-testing-enabled NO`. Step 7: passed on the explicit iPhone 15 UDID. Phase 11 still has to re-run § Verification on the release commit. Closed.
- Review follow-ups (after c6ed4da), each a new commit:
  - R-MK-1: CI resolves with no lockfile (analyzer 14.4.0 / source_gen 4.3.0), which writes a blank line after the mock header that 13.3.0 / 4.2.4 doesn't. Mocks were regenerated after `flutter pub upgrade`. The `codegen` job now checks the pigeon outputs with a strict `git diff --exit-code` and the mocks with `diff -B` against HEAD. Locally, plain `diff` on files is blocked by the permission config, so the local check uses a Python equivalent that compares non-blank lines; it accepts the old/new blank-line difference and rejects a real rename.
  - R-MK-3/6/7/8: added or strengthened macOS XCTests: snapshot wiring through `snapshotInput`, dispose clearing the location delegate and hiding user location, tap before select, top-most overlay inserted out of z-order, and `.aboveLabels` before `.aboveRoads`. One combined mutation run (config/appearance dropped from `snapshotInput`, location cleanup deleted, tap/select sends swapped, levels swapped, zIndex insertion ignored) turned exactly those 5 tests red and left the other 10 green; restored, 15/15 pass with warnings as errors.
  - Xcode on CI: the runner-images macos-15 readme (image 20260824.0482.1) lists Xcode 26.3, 26.2, 26.1.1 and 26.0.1 next to the default 16.4. Every macOS job (`example-apple`, `cocoapods-probe`, `integration`, `native-ios`) now runs `sudo xcode-select -s /Applications/Xcode_26.3.app`, the closest available to the Xcode 27 everything was compiled with locally. Flutter 3.47 requires Xcode ≥ 15 and recommends 16, so 26.3 satisfies both. Its iOS simulator runtimes are 18.5, 18.6 and 26.0–26.2. Unverified until the Phase 11 push.
  - R-MK-4: `example-apple` runs macOS integration in its own step: 420 s limit per file (perl alarm), one retry, salvage when the output says `All tests passed`, step cap 25 min. The job cap went from 45 to 60 min so the step fits after the builds and XCTest. The loop, extracted with `yq` and run once locally under `bash -e`, passed all 5 files on the first attempt (leak oracle `[]`, snapshot skipped).
  - `testEvChargerMapsOnEveryOS` can only go red on iOS 17. macos-15 has no iOS 17 runtime, so CI can't make it fail; it is enforced only by the local iPhone 15 / 17.5 run. No change.
- R-MK-2 resolved by user decision (2026-10-04): typed sentinels. All 14 nullable `copyWith` parameters keep their 0.3.7 types (`String?`, `VoidCallback?`, `ValueChanged<CLLocationCoordinate2D>?`, `List<double>?`) and default to a sentinel of that type. The sentinels are `keepString`, `keepDoubles`, `keepCallback` and `keepCoordinateCallback` in `lib/src/_internal/copy_with_keep.dart`, which replaces `unset.dart` and is not exported. They are `@internal` top-level names, not `_` names, because Dart privacy is per library and four model files share them. Resolution is `identical(x, keepX) ? this.x : x`. Red at the pre-change HEAD (ccbd2fb): `test/copy_with_test.dart` analyzed with 1 `invalid_assignment` error and 1 `inference_failure_on_untyped_parameter` warning on `copyWith(onDragEnd: (c) => last = c)`. Tests failed on `copyWith(lineDashPattern: [])` (`'List<dynamic>' is not a subtype of 'List<num>?'`) and on a dash pattern being stored as a copy rather than the value passed. After the change: analyze is clean and all 193 tests pass. These include omitted/null/value cases for all 14 parameters, `[]` and `const []` stored as empty, `const [1]` stored as `[1.0]`, and the `==`/`hashCode` rules including overlay `onTap != null`. `copyWith(title: 42)` is a compile error again (`argument_type_not_assignable`, checked in a scratch file that was deleted). Closed.
- Risk for Phase 11 CI (open; mitigated by R-MK-4's limit and retry): `example-apple` runs every integration file on a macOS runner with no retry. If the "Failed to foreground app" hang seen locally in `home_page_test` also hits a headless runner, the job reaches its 45-minute cap. The plan's Phase 10 traps cover only `cocoapods-probe` and `pana`; a red `example-apple` from this cause would need a decision in Phase 11.

## Execution prompt
Paste as turn 1 of a fresh session:
```text
Execute plans/sweep-fixes.md. It is self-contained and every decision in it is final: do not re-explore, re-decide, or propose architectural changes. Set its frontmatter status to in-progress, then start at the first unticked phase in § Progress, run its oracle, tick it, report the output, and continue phase by phase without waiting for me. Append anything the plan did not name to § Found; anything left open also gets a row in the tracker § Found names. The file is the state of record: after compaction, re-read it and resume from § Progress. Only when every § Verification step ran and passed, delete the plan file in your last commit — plans are ephemeral, git is the archive. A decision the plan does not cover: stop and ask me as a structured question.
```
