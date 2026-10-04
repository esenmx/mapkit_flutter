# mapkit_flutter

[![pub package](https://img.shields.io/pub/v/mapkit_flutter.svg)](https://pub.dev/packages/mapkit_flutter) [![pub points](https://img.shields.io/pub/points/mapkit_flutter)](https://pub.dev/packages/mapkit_flutter/score) [![CI](https://github.com/esenmx/mapkit_flutter/actions/workflows/ci.yaml/badge.svg)](https://github.com/esenmx/mapkit_flutter/actions/workflows/ci.yaml) [![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

MapKit for Flutter. Wraps `MKMapView` as a Flutter platform view on iOS and macOS, with annotations, overlays, clustering, Look Around, tile overlays, and the modern `MKMapConfiguration` family.

**Every public type carries Apple's exact MapKit symbol name** — `MKMapCamera`, `MKCoordinateRegion`, `MKPolyline`, `CLLocationCoordinate2D`. If you (or your coding agent) know MapKit, you already know this API. The `MK` namespace also means zero import collisions with `google_maps_flutter`, `mapbox_maps_flutter`, or `flutter_map` in mixed-platform code — no `as mk` prefixes needed.

> **Apple platforms only (iOS + macOS).** Apple's MapKit does not exist on Android. Pair this with `google_maps_flutter` behind a platform switch for cross-platform apps. Look Around is presented on iOS; on macOS `openLookAround` returns `false` (not wired yet).

## Install

```bash
flutter pub add mapkit_flutter
```

## Platform setup

Raise the app's deployment targets to the plugin's floor:

- **iOS 17.0** — `IPHONEOS_DEPLOYMENT_TARGET` on the Runner target (or Podfile `platform :ios, '17.0'`).
- **macOS 14.0** — `MACOSX_DEPLOYMENT_TARGET` on the Runner target (or Podfile `platform :osx, '14.0'`).

A Swift Package Manager app left on Flutter's default macOS 12.0 fails to build with "requires minimum platform version 14.0".

Add to `ios/Runner/Info.plist` (on macOS, `macos/Runner/Info.plist` plus the Location sandbox entitlement) if you set `showsUserLocation: true`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to show your current location on the map.</string>
```

### Minimum requirements

| | |
|---|---|
| iOS | 17.0 |
| macOS | 14.0 |
| Xcode | 16+ (the native code is Swift 6 language mode — data-race safety is compiler-enforced) |

## Platform differences

| | iOS | macOS |
|---|---|---|
| `onCalloutTap` | ✓ | ✗ (default callout) |
| Image-icon `anchorPoint` | ✓ | ✗ (centered) |
| `userTrackingMode: followWithHeading` | ✓ | falls back to `follow` |
| Snapshot annotation/overlay compositing | ✓ | ✗ (base map only) |
| `selectableMapFeatures` + `onMapFeatureSelected` | ✓ | ✗ |
| `openLookAround` | ✓ | returns `false` |
| `showsUserTrackingButton` | ✓ | ✓ |
| `onCameraMove` | continuous | continuous |
| `onDrag` | drag-state changes, not every movement | drag-state changes, not every movement |

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MKMapViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return MKMapView(
      initialCamera: const MKMapCamera(
        centerCoordinate: CLLocationCoordinate2D(
          latitude: 37.334922,
          longitude: -122.009033,
        ),
        distance: 1500, // meters, like MKMapCamera.centerCoordinateDistance
      ),
      showsUserLocation: true,
      annotations: {
        const MKPointAnnotation(
          id: MKAnnotationId('apple-park'),
          coordinate: CLLocationCoordinate2D(
            latitude: 37.334922,
            longitude: -122.009033,
          ),
          title: 'Apple Park',
          subtitle: 'One Apple Park Way',
        ),
      },
      onMapCreated: (controller) => _controller = controller,
      onTap: (coordinate) => debugPrint('tapped $coordinate'),
    );
  }
}
```

`Coordinate` is an exported alias for `CLLocationCoordinate2D`.

## The widget mirrors `MKMapView`

The base style is a sealed `preferredConfiguration` (exactly `MKMapView.preferredConfiguration`); view-level switches are direct parameters with their `MKMapView` property names:

```dart
MKMapView(
  initialCamera: ...,
  preferredConfiguration: const MKStandardMapConfiguration(
    elevationStyle: MKMapElevationStyle.realistic,
    emphasisStyle: MKMapEmphasisStyle.muted, // `standard` ≙ Apple's `.default`
    pointOfInterestFilter: MKPointOfInterestFilter.including([
      MKPointOfInterestCategory.cafe,
      MKPointOfInterestCategory.park,
    ]),
    showsTraffic: true,
  ),
  // MKHybridMapConfiguration() / MKImageryMapConfiguration() likewise.
  isZoomEnabled: true,
  isScrollEnabled: true,
  isRotateEnabled: false,
  isPitchEnabled: false,
  showsCompass: true,
  showsScale: true,
  showsUserLocation: true,
  showsUserTrackingButton: true,
  userTrackingMode: MKUserTrackingMode.follow,
  cameraZoomRange: const MKCameraZoomRange(
    minCenterCoordinateDistance: 500,    // meters
    maxCenterCoordinateDistance: 100000,
  ),
  cameraBoundary: someRegion,            // MKCoordinateRegion?
  selectableMapFeatures: {MKMapFeatureOptions.pointsOfInterest}, // iOS only
  onMapFeatureSelected: (feature) => debugPrint('${feature.title}'),
)
```

## Annotations

`MKPointAnnotation` merges the annotation (`coordinate`, `title`, `subtitle`) with its `MKAnnotationView` presentation (`alpha`, `isDraggable`, `zPriority`, `clusteringIdentifier`…) — Flutter is declarative, so there is no separate view object.

```dart
// System balloon marker (MKMarkerAnnotationView)
MKPointAnnotation(id: MKAnnotationId('home'), coordinate: home)

// Tinted + glyph-branded marker
MKPointAnnotation(
  id: MKAnnotationId('cafe'),
  coordinate: cafe,
  icon: MKAnnotationIcon.marker(
    markerTintColor: Colors.brown,
    systemImage: 'cup.and.saucer.fill',
    glyphTintColor: Colors.white,
  ),
)

// Custom image from an asset
final icon = await MKAnnotationIcon.asset('assets/pin.png');
MKPointAnnotation(id: MKAnnotationId('shop'), coordinate: shop, icon: icon)

// Fully custom marker from a rendered Flutter widget: capture PNG bytes
// (e.g. via RenderRepaintBoundary.toImage) and pass them through:
MKPointAnnotation(
  id: MKAnnotationId('w'),
  coordinate: here,
  icon: MKAnnotationIcon.image(pngBytes),
)

// Callout + selection + drag
MKPointAnnotation(
  id: MKAnnotationId('apple-park'),
  coordinate: applePark,
  title: 'Apple Park',
  subtitle: 'One Apple Park Way',
  onCalloutTap: () => Navigator.pushNamed(context, '/details'), // iOS
  onSelect: () => debugPrint('selected'),   // user or programmatic
  onDeselect: () => debugPrint('deselected'),
  isDraggable: true,
  onDragEnd: (coordinate) => print('dropped $coordinate'),
)
```

Annotations sharing a `clusteringIdentifier` cluster natively when they crowd.

## Overlays

`MKPolyline`, `MKPolygon`, `MKCircle`, `MKTileOverlay` — each merges its renderer's stroke/fill vocabulary (`strokeColor`, `lineWidth`, `lineDashPattern`):

```dart
MKMapView(
  initialCamera: ...,
  polylines: {
    MKPolyline(
      id: const MKPolylineId('route'),
      coordinates: const [...],
      strokeColor: Colors.blue,
      lineWidth: 6,
      lineCap: CGLineCap.round,
      lineJoin: CGLineJoin.round,
      lineDashPattern: const [6, 3],     // alternating dash/gap points
      gradientColors: const [Colors.green, Colors.red], // MKGradientPolylineRenderer
      level: MKOverlayLevel.aboveLabels,
    ),
    // Great-circle path, densified by native MKGeodesicPolyline:
    MKPolyline.geodesic(
      id: const MKPolylineId('sfo-nrt'),
      coordinates: const [sfo, nrt],
    ),
  },
  polygons: {
    MKPolygon(
      id: const MKPolygonId('zone'),
      coordinates: const [...],
      interiorPolygons: const [[...]],   // holes, MKPolygon-exact
      fillColor: Colors.red.withValues(alpha: 0.3),
      strokeColor: Colors.red,
    ),
  },
  circles: {
    MKCircle(
      id: const MKCircleId('radius'),
      center: const CLLocationCoordinate2D(latitude: ..., longitude: ...),
      radius: 500, // meters
    ),
  },
)
```

`onTap` implies `consumeTapEvents`; only the top-most overlay under a tap fires.

Tile overlays go through the controller (`MKTileOverlay(urlTemplate:)` semantics):

```dart
await controller.addTileOverlay(
  const MKTileOverlay(
    id: MKTileOverlayId('osm'),
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
);
```

Models override `==`, so they can't be used in `const {…}` set literals — build the set without `const`. `copyWith` clears a nullable field when you pass `null` explicitly:

```dart
final untitled = annotation.copyWith(title: null);
```

## Controller — `MKMapView`'s imperative surface

```dart
final MKMapCamera camera = await controller.camera;          // MKMapView.camera
final MKCoordinateRegion region = await controller.region;   // MKMapView.region
await controller.setCamera(camera, animated: true);          // setCamera(_:animated:)
await controller.setRegion(region, animated: true);          // setRegion(_:animated:)
await controller.setCenter(coordinate, animated: true);      // setCenter(_:animated:)
await controller.convertToPoint(coordinate);                 // convert(_:toPointTo:)
await controller.convertToCoordinate(offset);                // convert(_:toCoordinateFrom:)
await controller.showCallout(MKAnnotationId('a'));
await controller.openLookAround(coordinate);                 // MKLookAroundViewController
final Uint8List png = await controller.takeSnapshot(
  const MKMapSnapshotOptions(showsBuildings: false),         // MKMapSnapshotter.Options
);
```

Mutations run on an internal serial queue — concurrent calls execute in source order. `controller.dispose()` runs automatically when the owning `MKMapView` widget unmounts.

`MKMapViewController` is an interface, so the code you write against it is unit-testable without a platform view:

```dart
@GenerateNiceMocks([MockSpec<MKMapViewController>()])
void main() {
  // Nice mocks need a dummy for each non-nullable return type.
  setUpAll(() => provideDummy<MKMapCamera>(someCamera));

  test('recenters on the selected stop', () async {
    final controller = MockMKMapViewController();
    when(controller.camera).thenAnswer((_) async => someCamera);

    await MapPresenter(controller).select(stop);

    verify(controller.setCenter(stop.coordinate, animated: true)).called(1);
  });
}
```

## Two dialects

The canonical API is the MapKit mirror above. If you think in google_maps_flutter terms, the exported `CameraConveniences` extension layers that dialect on top — implemented purely over the canonical calls, no extra platform surface:

```dart
await controller.zoomTo(14);
await controller.zoomBy(2);
await controller.zoomIn();
await controller.scrollBy(80, -40);
await controller.fitCoordinates(
  annotations.map((a) => a.coordinate),
  padding: 0.1, // 10% of the span on each side
);
final zoom = await controller.getZoomLevel();
```

Zoom levels are a Web-Mercator convenience (`MKMapCamera.withZoomLevel` / `camera.zoomLevel`); MapKit's native unit is `distance` in meters.

## Errors

MapKit's imperative API doesn't throw, and neither do the mirrored calls. Expected conditions degrade instead: camera moves clamp, unknown ids are ignored (`showCallout` racing a rebuild that removed the annotation is harmless, matching `selectAnnotation` semantics), conversions return `null` before the first layout, and `openLookAround` returns `false` when no scene exists.

What can genuinely fail throws a typed `MapKitException` instead of a raw `PlatformException`:

```dart
try {
  final png = await controller.takeSnapshot();
} on MapKitPlatformException catch (e) {
  debugPrint('${e.code}: ${e.message}'); // e.g. snapshot-failed
}
```

- `MapKitPlatformException` — native failure with a stable `code` (`takeSnapshot` → `snapshot-failed`) plus the native `message` / `details`.
- `MapKitDisposedException` — controller used after the owning widget unmounted.
- `MapKitUnsupportedPlatformException` — `MKMapView` built off iOS/macOS.

Failures MKMapView reports through its delegate surface as widget callbacks: `onDidFailToLocateUser` (most commonly location permission denied) and `onDidFailLoadingMap` (map content failed to load, e.g. offline).

## Type-safe platform channel

The Dart↔Swift boundary is generated by [Pigeon](https://pub.dev/packages/pigeon) from [`pigeons/messages.dart`](pigeons/messages.dart). After editing the schema, regenerate with `dart run pigeon --input pigeons/messages.dart && dart format lib/src/messages.g.dart`.

The outputs (`lib/src/messages.g.dart`, `darwin/mapkit_flutter/Sources/mapkit_flutter/messages.g.swift`) are committed and must not be hand-edited; CI regenerates and fails on drift. Wire types keep a `Platform` prefix so the generated Swift never shadows real MapKit symbols; public Dart names are restored via `typedef` (e.g. `MKUserTrackingMode`).

## Agent skill

This package ships an agent skill in `skills/mapkit-flutter-scaffold/`. Install it into your project's agent config with:

```sh
dart run skills@ get --package mapkit_flutter --all
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [`LICENSE`](LICENSE).
