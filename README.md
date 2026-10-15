# mapkit_flutter

[![pub package](https://img.shields.io/pub/v/mapkit_flutter.svg)](https://pub.dev/packages/mapkit_flutter) [![pub points](https://img.shields.io/pub/points/mapkit_flutter)](https://pub.dev/packages/mapkit_flutter/score) [![CI](https://github.com/esenmx/mapkit_flutter/actions/workflows/ci.yaml/badge.svg)](https://github.com/esenmx/mapkit_flutter/actions/workflows/ci.yaml) [![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

MapKit for Flutter. Wraps `MKMapView` as a Flutter platform view on iOS and macOS, with annotations, overlays, clustering, Look Around, tile overlays, and the modern `MKMapConfiguration` family.

**Every public type carries Apple's exact MapKit symbol name** — `MKMapCamera`, `MKCoordinateRegion`, `MKPolyline`, `CLLocationCoordinate2D`. If you (or your coding agent) know MapKit, you already know this API. The `MK` namespace also means zero import collisions with `google_maps_flutter`, `mapbox_maps_flutter`, or `flutter_map` in mixed-platform code — no `as mk` prefixes needed.

> **Apple platforms only (iOS + macOS).** Apple's MapKit does not exist on Android. Pair this with `google_maps_flutter` behind a platform switch for cross-platform apps. A few settings are iOS only; using one on macOS throws instead of being silently ignored (see [Platform differences](#platform-differences)).

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

Like `MKMapView`, the map never asks for location permission itself: request when-in-use authorization in your app (e.g. with `permission_handler` or a `CLLocationManager` channel) at the moment that makes sense for your UI. Without it, `onDidFailToLocateUser` reports the failure.

### Minimum requirements

| | |
|---|---|
| iOS | 17.0 |
| macOS | 14.0 |
| Xcode | 16+ (the native code is Swift 6 language mode — data-race safety is compiler-enforced) |

## Platform differences

| | iOS | macOS |
|---|---|---|
| `calloutConsumesTapEvents` / `onCalloutTap` | ✓ | throws (default callout) |
| Image-icon `anchorPoint` | ✓ | ✓ |
| `userTrackingMode: followWithHeading` | ✓ | throws |
| Snapshot annotation/overlay compositing | ✓ | ✓ |
| `selectableMapFeatures` + `onMapFeatureSelected` | ✓ | throws |
| `insetsLayoutMarginsFromSafeArea: false` | ✓ | throws |
| `openLookAround` | ✓ | throws `unsupported-platform` |
| `showsUserTrackingButton` | ✓ | ✓ |
| `onCameraMove` | continuous | continuous |

"Throws" means building `MKMapView` with that setting on macOS throws a `MapKitUnsupportedPlatformException` naming it.

## Quick start

```dart
import 'package:flutter/widgets.dart';
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
      initialCamera: MKMapCamera(
        centerCoordinate: CLLocationCoordinate2D(
          latitude: 37.334922,
          longitude: -122.009033,
        ),
        distance: 1500, // meters, like MKMapCamera.centerCoordinateDistance
      ),
      annotations: {
        MKPointAnnotation(
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

Value types validate in every build mode and throw an `ArgumentError` for input MapKit can't represent — a latitude outside `[-90, 90]` (swapped arguments), a non-finite number, a negative `lineWidth`, `alpha` outside `[0, 1]`, a zoom range whose minimum exceeds its maximum. That is why they have no `const` constructors. Longitude wraps into `[-180, 180)` like MapKit. Ids must be unique per kind; two annotations (or two polylines…) sharing an id throw when `MKMapView` builds.

## The widget mirrors `MKMapView`

The base style is a sealed `preferredConfiguration` (exactly `MKMapView.preferredConfiguration`); view-level switches are direct parameters with their `MKMapView` property names:

<!-- no-compile -->
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
  userTrackingMode: _trackingMode,            // applied when it changes
  onUserTrackingModeChanged: (mode) =>        // MapKit drops to .none on pan
      setState(() => _trackingMode = mode),
  cameraZoomRange: MKCameraZoomRange(
    minCenterCoordinateDistance: 500,    // meters
    maxCenterCoordinateDistance: 100000,
  ),
  cameraBoundary: someRegion,            // MKCoordinateRegion?
  selectableMapFeatures: {MKMapFeatureOptions.pointsOfInterest}, // iOS only
  onMapFeatureSelected: (feature) => debugPrint('${feature.title}'), // iOS only
)
```

## Annotations

`MKPointAnnotation` merges the annotation (`coordinate`, `title`, `subtitle`) with its `MKAnnotationView` presentation (`alpha`, `isDraggable`, `zPriority`, `clusteringIdentifier`…) — Flutter is declarative, so there is no separate view object.

<!-- no-compile -->
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
  calloutConsumesTapEvents: true,                               // iOS
  onCalloutTap: () => Navigator.pushNamed(context, '/details'), // needs it
  onSelect: () => debugPrint('selected'),   // user tap or selectAnnotation
  onDeselect: () => debugPrint('deselected'),
  isDraggable: true,
  onDragEnd: (coordinate) => debugPrint('dropped $coordinate'),
)
```

Annotations sharing a `clusteringIdentifier` cluster natively when they crowd. Image bytes the platform can't decode, or an SF Symbol name it doesn't know, fail the map update with a `MapKitPlatformException` (`invalid-icon`) instead of rendering an invisible or plain pin.

## Overlays

`MKPolyline`, `MKPolygon`, `MKCircle`, `MKTileOverlay` — each merges its renderer's stroke/fill vocabulary (`strokeColor`, `lineWidth`, `lineDashPattern`):

<!-- no-compile -->
```dart
MKMapView(
  initialCamera: ...,
  polylines: {
    MKPolyline(
      id: const MKPolylineId('route'),
      coordinates: [...],
      strokeColor: Colors.blue,
      lineWidth: 6,
      lineCap: CGLineCap.round,
      lineJoin: CGLineJoin.round,
      lineDashPattern: const [6, 3],     // alternating dash/gap points
      gradientColors: const [Colors.green, Colors.red], // ≥ 2 colors
      level: MKOverlayLevel.aboveLabels,
      consumeTapEvents: true,            // capture taps…
      onTap: () => debugPrint('route'),  // …to receive them
    ),
    // Great-circle path, densified by native MKGeodesicPolyline:
    MKPolyline.geodesic(
      id: const MKPolylineId('sfo-nrt'),
      coordinates: [sfo, nrt],
    ),
  },
  polygons: {
    MKPolygon(
      id: const MKPolygonId('zone'),
      coordinates: [...],
      interiorPolygons: [[...]],         // holes, MKPolygon-exact
      fillColor: Colors.red.withValues(alpha: 0.3),
      strokeColor: Colors.red,
    ),
  },
  circles: {
    MKCircle(
      id: const MKCircleId('radius'),
      center: CLLocationCoordinate2D(latitude: ..., longitude: ...),
      radius: 500, // meters
    ),
  },
)
```

Only overlays with `consumeTapEvents: true` capture taps; the top-most capturing overlay under a tap fires its `onTap`, and the tap doesn't reach the map's `onTap`. Setting `onTap` without `consumeTapEvents` throws an `ArgumentError` — it could never fire. Polyline hit-testing covers the visible stroke (half the `lineWidth`, at least 8 points).

Tile overlays go through the controller (`MKTileOverlay(urlTemplate:)` semantics):

```dart
Future<void> addOsm(MKMapViewController controller) async {
  await controller.addTileOverlay(
    MKTileOverlay(
      id: const MKTileOverlayId('osm'),
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
  );
  final removed = await controller.removeTileOverlay(
    const MKTileOverlayId('osm'),
  );
}
```

Adding an id that is already on the map throws (`duplicate-id`); remove it first to replace it. `removeTileOverlay` returns `false` when the id isn't on the map.

Models override `==`, so they can't be used in `const {…}` set literals — build the set without `const`. `copyWith` clears a nullable field when you pass `null` explicitly:

```dart
MKPointAnnotation untitled(MKPointAnnotation annotation) =>
    annotation.copyWith(title: null);
```

## Controller — `MKMapView`'s imperative surface

```dart
Future<void> tour(
  MKMapViewController controller,
  Coordinate coordinate,
  Offset offset,
) async {
  final MKMapCamera? camera = await controller.camera;         // MKMapView.camera
  final MKCoordinateRegion? region = await controller.region;  // MKMapView.region
  await controller.setCamera(camera!, animated: true);         // setCamera(_:animated:)
  await controller.setRegion(region!, animated: true);         // setRegion(_:animated:)
  await controller.setCenter(coordinate, animated: true);      // setCenter(_:animated:)
  await controller.convertToPoint(coordinate);                 // convert(_:toPointTo:)
  await controller.convertToCoordinate(offset);                // convert(_:toCoordinateFrom:)
  final bool selected =
      await controller.selectAnnotation(MKAnnotationId('a'));  // selectAnnotation(_:animated:)
  await controller.deselectAnnotation(MKAnnotationId('a'));    // deselectAnnotation(_:animated:)
  await controller.isAnnotationSelected(MKAnnotationId('a'));  // selectedAnnotations
  await controller.openLookAround(coordinate);                 // MKLookAroundViewController
  final Uint8List png = await controller.takeSnapshot(
    const MKMapSnapshotOptions(showsPointsOfInterest: false),  // MKMapSnapshotter.Options
  );
}
```

`camera`, `region` and the conversions return `null` before the view's first layout — there is no meaningful camera for a zero-sized view yet. `selectAnnotation` / `deselectAnnotation` return `false` when the id isn't on the map (e.g. racing a rebuild that removed it) and `selectAnnotation` also for a hidden annotation, so you can tell whether anything happened.

Mutations run on an internal serial queue — concurrent calls execute in source order. `controller.dispose()` runs automatically when the owning `MKMapView` widget unmounts.

`MKMapViewController` is an interface, so the code you write against it is unit-testable without a platform view:

<!-- no-compile -->
```dart
@GenerateNiceMocks([MockSpec<MKMapViewController>()])
void main() {
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
Future<void> frame(
  MKMapViewController controller,
  Set<MKPointAnnotation> annotations,
) async {
  await controller.zoomTo(14);
  await controller.zoomBy(2);
  await controller.zoomIn();
  await controller.scrollBy(80, -40);
  await controller.fitCoordinates(
    annotations.map((a) => a.coordinate),
    padding: 0.1, // 10% of the span on each side
  );
  final zoom = await controller.getZoomLevel();
}
```

Zoom levels are a Web-Mercator convenience (`MKMapCamera.withZoomLevel` / `camera.zoomLevel`); MapKit's native unit is `distance` in meters. The camera-relative helpers throw a `StateError` before the view's first layout, and `fitCoordinates` throws an `ArgumentError` for an empty list or a negative `padding` / `minimumSpan`.

## Errors

Misuse fails loudly, in debug and release alike, close to its cause:

- **Invalid values** throw an `ArgumentError` from the constructor (see above), including `onTap` without `consumeTapEvents` and `onCalloutTap` without `calloutConsumesTapEvents`.
- **Duplicate ids** in one of `MKMapView`'s sets throw an `ArgumentError` when the widget builds or updates.
- **iOS-only settings on macOS** throw a `MapKitUnsupportedPlatformException` whose `feature` names the setting.
- **Use after dispose** throws a `MapKitDisposedException`.

Native failures surface as a `MapKitPlatformException` with a stable `code` plus the native `message` / `details`:

| Code | When |
|---|---|
| `snapshot-failed` | `takeSnapshot` produced no image (e.g. tile loading failed, zero-sized view) |
| `look-around-failed` | the Look Around scene request failed (e.g. offline) or there is no view controller to present from |
| `unsupported-platform` | `openLookAround` on macOS |
| `duplicate-id` | `addTileOverlay` with an id already on the map |
| `invalid-icon` | annotation image bytes that don't decode, or an unknown SF Symbol |
| `unavailable-poi-category` | a `MKPointOfInterestFilter` naming a category newer than the running OS (iOS 18 / macOS 15 values) |
| `invalid-argument` | a zoom range or camera boundary MapKit rejects |

```dart
Future<void> snapshot(MKMapViewController controller) async {
  try {
    final png = await controller.takeSnapshot();
  } on MapKitPlatformException catch (e) {
    debugPrint('${e.code}: ${e.message}');
  }
}
```

Errors from declarative content (annotations, overlays, configuration) happen while `MKMapView` pushes an update, outside any call you await, so they surface as uncaught errors in the zone — they don't vanish.

What isn't an error is reported as a value: `openLookAround` returns `false` when no Look Around scene exists for the coordinate, `selectAnnotation` / `deselectAnnotation` / `removeTileOverlay` return `false` when the id isn't on the map, and `camera` / `region` / conversions return `null` before the first layout. Failures MKMapView reports through its delegate surface as widget callbacks: `onDidFailToLocateUser` (most commonly missing location permission) and `onDidFailLoadingMap` (map content failed to load, e.g. offline).

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
