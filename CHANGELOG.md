# Changelog

## 0.4.0 - 2026-10-04

### Breaking

- MKPointOfInterestCategory gained 33 values — exhaustive switches over it must handle them.
- `copyWith(x: null)` now clears a nullable field instead of keeping it, so code that passes a possibly-null variable changes behaviour. Parameter types are unchanged from 0.3.7; omitting the argument still keeps the field.
- The agent skill moved to skills/mapkit-flutter-scaffold/ (dart run skills@ get requires the package-name prefix).

### Added

- MKPointAnnotation.onSelect / onDeselect.
- MKMapView.onMapFeatureSelected (iOS) with MKMapFeature / MKMapFeatureType.
- 33 iOS 18 / macOS 15 MKPointOfInterestCategory values (ignored by filters on older OS versions).
- Apple privacy manifest (PrivacyInfo.xcprivacy) for SPM and CocoaPods.

### Changed

- Requires Dart 3.13 / Flutter 3.47 (was Dart 3.10 / Flutter 3.41).
- Platform channel regenerated with Pigeon 29; host→Dart events use its async Swift API.
- An overlay with onTap now consumes taps (onTap implies consumeTapEvents).
- fitCoordinates gains padding and minimumSpan; a single coordinate now frames 0.005° instead of zooming fully in.
- Only the top-most visible consuming overlay receives a tap (was every overlay under the point).
- `userTrackingMode` is re-applied only when it changes, so unrelated rebuilds no longer snap a panned map back to tracking.
- `showsUserTrackingButton` works on macOS.
- MKMapSnapshotOptions.showsBuildings has no effect (MapKit dropped it).
- onCameraMove fires continuously (gestures, momentum, animations) on iOS and macOS via mapViewDidChangeVisibleRegion.
- Docs: Look Around and showsUserTrackingButton platform notes corrected; per-platform differences table; deployment-target setup.

### Fixed

- Package.swift declares the FlutterFramework dependency (silences the Flutter 3.47 build warning).
- Unmounting a map now releases its native MKMapView, host and location manager (channel handlers were never removed).
- Geodesic polylines no longer corrupt memory on iOS/macOS 27 (MKGeodesicPolyline is no longer subclassed).
- A rebuild that lands before the platform view finishes creating no longer leaves taps on stale callbacks.
- In-range longitudes are stored verbatim (normalisation used to perturb them, e.g. 10.1 → 10.099999999999994).
- `initialize` sends one object per id, last wins, like the rebuild diff; duplicate ids now assert in debug.
- Toggling `onCalloutTap` on an existing annotation now reaches native.
- The first annotation update after a drag is no longer dropped (Dart stays the source of truth: a drag the app ignores snaps back on the next changed rebuild).
- `MKPointOfInterestCategory.evCharger` works on iOS 17 (an `including` filter with it no longer hides every POI).
- Custom-image annotation callouts are no longer offset sideways.
- `onCalloutTap` fires once per tap after reselecting an annotation (iOS).
- Hidden overlays never take taps.
- Re-adding a tile overlay with the same id (including the empty id) replaces it.
- Snapshots now match the on-screen map: style (hybrid/imagery/muted/traffic/elevation/POI filter), rotated/pitched camera and dark mode.
- Snapshot polygon outlines start without a zero-length edge and draw the closing edge once (visible with dash patterns and translucent strokes).
- The podspec no longer forces -warnings-as-errors on CocoaPods consumers.

### Removed

- The hand-patched pigeon deepEquals dictionary branch (dead code — the schema has no Map fields) and the unused ios/ copy of the generated Swift file.

## 0.3.7

- Fix: iOS snapshot polylines now stroke as a single subpath, so `lineJoin` applies and dash patterns run continuously across vertices. A single-coordinate polyline now draws nothing instead of a round-cap dot, matching the live renderer.
- Performance: iOS snapshots skip annotations whose drawn frame lies entirely outside the image; partially visible edge annotations still draw.
- Fix: podspec version now tracks pubspec — CocoaPods had advertised 0.3.0 since v0.3.1. CI guards against drift (and fails closed if no podspec matches).
- CI: macOS example build job added alongside iOS; integration workflow bounds every `flutter test` invocation and recycles a wedged simulator between retries.

## 0.3.6

- Testing: `MKMapViewController` is now an interface (`abstract interface class`) instead of a `final class`, so code that drives a map can be mocked or faked in unit tests. The widget-only mutations (`initialize`, `update*`) moved to the internal `MKMapViewControllerImpl`, keeping the mockable surface to the public API.

## 0.3.5

- Fix: Marker annotation views dequeue with a safe cast and fallback instead of a forced downcast, hardening against a potential native crash.
- Performance: Hoisted the repeated `points()` accessor out of the polyline hit-testing loop.

## 0.3.4

- Performance: Refactored Pigeon deep equality checks for maps to O(N), speeding up Flutter configuration passes.
- Performance: Overhauled overlay updates to use a true O(1) class-level tracking dictionary (`overlaysById`), eliminating O(N) localized allocation overheads and massively improving performance when animating individual overlays in large collections.
- Fix: Addressed a Swift "ghost overlay" logic flaw where overlays being simultaneously removed and updated could fall out of sync with the underlying `MKMapView`.

## 0.3.3

- Fix: Per-object tap callbacks (annotation/polyline/polygon/circle) refresh on callback-only rebuilds.
- Fix: Toggling `onCalloutTap` propagates to the native callout.
- Fix: Guard polyline tap hit-testing against an empty coordinate list.

## 0.3.2

- Docs: Updated scaffolder skill (`skills/mapkit-flutter-scaffold/SKILL.md`) to document overlay tap interactions and macOS snapshot limitations.

## 0.3.1

- Performance: Refactored annotation dequeuing to use generic reuse identifiers, enabling proper MapKit view recycling.
- Fix: Preserved selection state (callouts) when swapping marker/image types in-place.
- Fix: Repaired overlay tap containment tests for circles and polygons which were failing on unrendered local paths.
- Build: Added strict compiler flags (`-warnings-as-errors`, `-strict-concurrency=complete`) and resolved iOS/macOS platform optionality discrepancies.
- Docs: Correct lingering iOS-only references to iOS + macOS; add `macos` topic.

## 0.3.0

- Added macOS support (Look Around stays iOS-only).
- Annotations now restyle correctly on in-place update and view reuse, including marker ↔ custom-image swaps.

## 0.2.1

- Silenced iOS build warnings for cleaner integration.

## 0.2.0

- Added Swift Package Manager support.

## 0.1.1

- Corrected supported platforms.

## 0.1.0

Initial release.
