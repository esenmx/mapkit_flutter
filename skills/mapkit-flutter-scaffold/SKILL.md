---
name: mapkit-flutter-scaffold
description: Scaffold or extend an Apple Maps page with package:mapkit_flutter. iOS and macOS.
disable-model-invocation: true
---

# mapkit-flutter-scaffold

One import: `package:mapkit_flutter/mapkit_flutter.dart`. **Every public type uses Apple's exact MapKit symbol name** — `MKMapView`, `MKMapCamera`, `MKCoordinateRegion(center:span:)`, `MKPointAnnotation`, `MKPolyline` / `MKPolygon` / `MKCircle` / `MKTileOverlay`, `MKPointOfInterestFilter`, `MKStandardMapConfiguration`, `CLLocationCoordinate2D(latitude:longitude:)`, `CGLineCap`… Predict the API from Swift MapKit knowledge; only the divergences below need stating. iOS 17 / macOS 14 floor; iOS + macOS (throws `MapKitUnsupportedPlatformException` on non-Apple platforms) — a handful of features are iOS-only (flagged below).

## Divergences from raw MapKit

- `MKMapView` is a declarative StatefulWidget: content is `Set<MKPointAnnotation>` / `Set<MKPolyline>` / … params, diffed on rebuild. Same id + changed fields → update; removed from set → removed from map.
- No view/renderer objects: presentation props are merged onto the models — `MKPointAnnotation(icon:, alpha:, isDraggable:, zPriority:, clusteringIdentifier:)`, `MKPolyline(strokeColor:, lineWidth:, lineDashPattern:)`.
- Ids are required phantom-typed values: `MKAnnotationId('x')`, `MKPolylineId('x')`, … — not interchangeable.
- The imperative half lives on `MKMapViewController` (from `onMapCreated`; non-null only inside/after it): `camera`/`region` getters, `setCamera`/`setRegion`/`setCenter(animated:)`, `convertToPoint`/`convertToCoordinate`, `showCallout`, `takeSnapshot(MKMapSnapshotOptions(...))` (on macOS, only the base map is captured; annotation/overlay compositing is iOS-only), `openLookAround(coordinate)` (presented on iOS; `false` on macOS), `addTileOverlay`. Calls run on an internal serial queue — don't coordinate; failures throw `MapKitException` subtypes. `dispose()` is automatic on unmount. It's an interface → mock it directly (`MockSpec<MKMapViewController>`; nice mocks need `provideDummy<MKMapCamera>` / `<MKCoordinateRegion>`) instead of hiding it behind a wrapper.
- Callbacks: `onSelect`/`onDeselect` per annotation; `onMapFeatureSelected` (iOS, needs `selectableMapFeatures`); `onCameraMove` is continuous (every visible-region change). `copyWith(x: null)` clears a nullable field.
- Error contract: only `takeSnapshot` throws in normal use (`MapKitPlatformException`, code `snapshot-failed`); unknown ids no-op (race-safe), conversions return `null` pre-layout, `openLookAround` returns `false` when unavailable. Delegate failures surface as widget callbacks `onDidFailToLocateUser` (e.g. location permission denied) / `onDidFailLoadingMap`, payload = error description.
- Tap callbacks: `MKPointAnnotation.onTap` / `onCalloutTap` (iOS); overlays' `onTap` implies `consumeTapEvents`, and only the top-most visible overlay fires.
- Style config (`preferredConfiguration:`) carries only elevation/emphasis/POI/traffic; `MKMapView` properties (`isZoomEnabled`, `showsCompass`, `showsUserTrackingButton`, `cameraZoomRange`, `cameraBoundary`, `selectableMapFeatures`…) are direct widget params. `selectableMapFeatures` is iOS-only (ignored on macOS); `showsUserTrackingButton` works on both.
- google_maps_flutter dialect available via the exported `CameraConveniences` extension: `zoomTo/zoomBy/zoomIn/zoomOut/scrollBy/fitCoordinates/getZoomLevel` — pure Dart over the canonical calls.
- `MKMapCamera.distance` is meters (`centerCoordinateDistance`); `MKMapCamera.withZoomLevel(...)` / `camera.zoomLevel` convert Web-Mercator zoom levels approximately.
- `MKMapEmphasisStyle.standard` ≙ Apple's `.default` (Dart reserved word). `isHidden` replaces `visible` everywhere. Geodesics: `MKPolyline.geodesic(...)` named constructor (maps to `MKGeodesicPolyline`).
- Custom marker imagery: `MKAnnotationIcon.marker(markerTintColor:/glyphText:/systemImage:/glyphTintColor:)`, `.image(pngBytes)`, or `await MKAnnotationIcon.asset('assets/pin.png')`.
- `Coordinate` is a typedef for `CLLocationCoordinate2D`; enum typedefs point at generated `Platform*` enums — cosmetic only.
- `showsUserLocation: true` → add `NSLocationWhenInUseUsageDescription` to `ios/Runner/Info.plist` (macOS: `macos/Runner/Info.plist`, plus the Location sandbox entitlement).
