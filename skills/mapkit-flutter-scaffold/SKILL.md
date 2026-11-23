---
name: mapkit-flutter-scaffold
description: 'Scaffold or extend an Apple Maps screen in Flutter on iOS and macOS via `package:mapkit_flutter/mapkit_flutter.dart` — MKMapView widget, pins and custom markers, clustering, polylines, polygons, circles, tile overlays, camera and region control, snapshots, Look Around, mocking MKMapViewController. Use for any map in an Apple-only Flutter app or its MapKit code. Skip for Android or web maps (`google_maps_flutter`, `flutter_map`), Mapbox (`mapbox_maps_flutter`).'
license: MIT
---

# mapkit-flutter-scaffold

One import: `package:mapkit_flutter/mapkit_flutter.dart`. Every public type uses Apple's exact MapKit symbol name (`MKMapView`, `MKMapCamera`, `MKCoordinateRegion`, `MKPointAnnotation`, `MKPolyline`/`MKPolygon`/`MKCircle`/`MKTileOverlay`, `MKPointOfInterestFilter`, `MKStandardMapConfiguration`, `CLLocationCoordinate2D`, `CGLineCap`…). Predict from Swift MapKit; only divergences matter. Floor: iOS 17 / macOS 14; non-Apple platforms throw `MapKitUnsupportedPlatformException`.

## Lazy references

- Markers/icons, overlays, tap capture, callbacks, style config, iOS-only props, `CameraConveniences`, `MKMapCamera` zoom/distance, snapshots, Look Around, tile overlays -> [references/features.md](references/features.md).

## Core model & contracts

- **Declarative `MKMapView`**: pass `Set<MKPointAnnotation>`/`Set<MKPolyline>`/…; diffed on rebuild (new set or in-place mutation + `setState` both work). Same id + changed fields -> update; absent -> removed. No renderer objects: presentation props sit on models (`icon:`, `alpha:`, `isDraggable:`, `zPriority:`, `clusteringIdentifier:`, `strokeColor:`, `lineWidth:`, `lineDashPattern:`).
- **Phantom IDs**: `MKAnnotationId('x')`, `MKPolylineId('x')`, … — distinct per kind, unique (duplicate throws `ArgumentError` on build).
- **Strict validation (every build mode)**: invalid values throw `ArgumentError` (no clamping: lat outside `[-90,90]`, non-finite, negative width/radius, alpha outside `[0,1]`, pitch outside `[0,90)`, min>max zoom, 1 gradient color, `imagePixelRatio <= 0`), so value types have no `const` ctors. Longitude wraps into `[-180,180)`. `MKCameraZoomRange.unbounded` is const. `MKPolyline`/`MKPolygon`/`MKPointOfInterestFilter.including`/`.excluding` copy lists unmodifiably (not `const`: `MKPointOfInterestFilter.including(const [...])`).
- **`MKMapViewController`**: from `onMapCreated` (non-null inside/after); serial queue (no manual locking); auto-disposed on unmount; interface -> mock directly (`MockSpec<MKMapViewController>`). `camera`/`region`/`convertToPoint`/`convertToCoordinate` return `null` pre-layout.
- **Errors**: `ArgumentError` (bad args/dup ids), `MapKitUnsupportedPlatformException` (iOS-only on macOS, or web/Android), `MapKitDisposedException` (post-dispose controller call), `MapKitPlatformException` with `code`: `snapshot-failed`, `look-around-failed`, `unsupported-platform`, `duplicate-id`, `invalid-icon` (bad bytes/SF Symbol), `unavailable-poi-category` (iOS 18/macOS 15 on older OS), `invalid-argument`. Declarative batch errors go to uncaught zone (batch stays unapplied; next set change resends all). Delegate errors -> `onDidFailToLocateUser` / `onDidFailLoadingMap` (payload = description).
- **Naming**: `MKMapEmphasisStyle.standard` = Apple `.default`; `isHidden` replaces `visible`; `Coordinate` = typedef `CLLocationCoordinate2D`; enum typedefs alias generated `Platform*` enums.
- **Permissions**: `showsUserLocation: true` requires `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist` (macOS: `macos/Runner/Info.plist` + Location sandbox entitlement) and app-initiated authorization — map never prompts.
