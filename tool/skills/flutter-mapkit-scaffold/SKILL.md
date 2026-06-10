---
name: flutter-mapkit-scaffold
description: Scaffold or extend an Apple Maps page with package:mapkit_flutter. iOS-only.
disable-model-invocation: true
---

# flutter-mapkit-scaffold

One import: `package:mapkit_flutter/mapkit_flutter.dart`. **Every public type uses Apple's exact MapKit symbol name** — `MKMapView`, `MKMapCamera`, `MKCoordinateRegion(center:span:)`, `MKPointAnnotation`, `MKPolyline` / `MKPolygon` / `MKCircle` / `MKTileOverlay`, `MKPointOfInterestFilter`, `MKStandardMapConfiguration`, `CLLocationCoordinate2D(latitude:longitude:)`, `CGLineCap`… Predict the API from Swift MapKit knowledge; only the divergences below need stating. iOS 17 floor; iOS-only (throws `MapKitUnsupportedPlatformException` elsewhere).

## Divergences from raw MapKit

- `MKMapView` is a declarative StatefulWidget: content is `Set<MKPointAnnotation>` / `Set<MKPolyline>` / … params, diffed on rebuild. Same id + changed fields → update; removed from set → removed from map.
- No view/renderer objects: presentation props are merged onto the models — `MKPointAnnotation(icon:, alpha:, isDraggable:, zPriority:, clusteringIdentifier:)`, `MKPolyline(strokeColor:, lineWidth:, lineDashPattern:)`.
- Ids are required phantom-typed values: `MKAnnotationId('x')`, `MKPolylineId('x')`, … — not interchangeable.
- The imperative half lives on `MKMapViewController` (from `onMapCreated`; non-null only inside/after it): `camera`/`region` getters, `setCamera`/`setRegion`/`setCenter(animated:)`, `convertToPoint`/`convertToCoordinate`, `showCallout`, `takeSnapshot(MKMapSnapshotOptions(...))`, `openLookAround(coordinate)`, `addTileOverlay`. Calls run on an internal serial queue — don't coordinate; failures throw `MapKitException` subtypes. `dispose()` is automatic on unmount.
- Error contract: only `takeSnapshot` throws in normal use (`MapKitPlatformException`, code `snapshot-failed`); unknown ids no-op (race-safe), conversions return `null` pre-layout, `openLookAround` returns `false` when unavailable. Delegate failures surface as widget callbacks `onDidFailToLocateUser` (e.g. location permission denied) / `onDidFailLoadingMap`, payload = error description.
- Style config (`preferredConfiguration:`) carries only elevation/emphasis/POI/traffic; `MKMapView` properties (`isZoomEnabled`, `showsCompass`, `showsUserTrackingButton`, `cameraZoomRange`, `cameraBoundary`, `selectableMapFeatures`…) are direct widget params.
- google_maps_flutter dialect available via the exported `CameraConveniences` extension: `zoomTo/zoomBy/zoomIn/zoomOut/scrollBy/fitCoordinates/getZoomLevel` — pure Dart over the canonical calls.
- `MKMapCamera.distance` is meters (`centerCoordinateDistance`); `MKMapCamera.withZoomLevel(...)` / `camera.zoomLevel` convert Web-Mercator zoom levels approximately.
- `MKMapEmphasisStyle.standard` ≙ Apple's `.default` (Dart reserved word). `isHidden` replaces `visible` everywhere. Geodesics: `MKPolyline.geodesic(...)` named constructor (maps to `MKGeodesicPolyline`).
- Custom marker imagery: `MKAnnotationIcon.marker(markerTintColor:/glyphText:/systemImage:/glyphTintColor:)`, `.image(pngBytes)`, or `await MKAnnotationIcon.asset('assets/pin.png')`.
- `Coordinate` is a typedef for `CLLocationCoordinate2D`; enum typedefs point at generated `Platform*` enums — cosmetic only.
- `showsUserLocation: true` → add `NSLocationWhenInUseUsageDescription` to `ios/Runner/Info.plist`.
