# Changelog

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

- Docs: Updated scaffolder skill (`tool/skills/flutter-mapkit-scaffold/SKILL.md`) to document overlay tap interactions and macOS snapshot limitations.

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
