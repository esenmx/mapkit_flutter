# Controller, helpers and errors

## Controller

`MKMapViewController` is `MKMapView`'s imperative surface. You get it from
`onMapCreated`, and every member returns a `Future`:

```dart
Future<void> tour(
  MKMapViewController controller,
  Coordinate coordinate,
  Offset offset,
) async {
  if (await controller.camera case final camera?) {
    await controller.setCamera(camera.copyWith(distance: camera.distance / 2));
  }
  if (await controller.region case final region?) {
    await controller.setRegion(region, animated: false);
  }
  await controller.setCenter(coordinate);
  final point = await controller.convertToPoint(coordinate);
  final tapped = await controller.convertToCoordinate(offset);
  const id = MKAnnotationId('apple-park');
  final selected = await controller.selectAnnotation(id);
  await controller.deselectAnnotation(id);
  final isSelected = await controller.isAnnotationSelected(id);
  final opened = await controller.openLookAround(coordinate);
  final png = await controller.takeSnapshot(
    const MKMapSnapshotOptions(showsPointsOfInterest: false),
  );
}
```

| Member | MapKit |
| --- | --- |
| `camera` | `MKMapView.camera` |
| `region` | `MKMapView.region` |
| `setCamera(camera, animated:)` | `setCamera(_:animated:)` |
| `setRegion(region, animated:)` | `setRegion(_:animated:)` |
| `setCenter(coordinate, animated:)` | `setCenter(_:animated:)` |
| `convertToPoint(coordinate)` | `convert(_:toPointTo:)` |
| `convertToCoordinate(offset)` | `convert(_:toCoordinateFrom:)` |
| `selectAnnotation(id)` | `selectAnnotation(_:animated:)` |
| `deselectAnnotation(id)` | `deselectAnnotation(_:animated:)` |
| `isAnnotationSelected(id)` | `selectedAnnotations` |
| `openLookAround(coordinate)` | `MKLookAroundViewController` |
| `takeSnapshot([options])` | `MKMapSnapshotter` |
| `addTileOverlay(overlay)` | `addOverlay(_:level:)` |
| `removeTileOverlay(id)` | `removeOverlay(_:)` |
| `dispose()` | — |

`animated` defaults to `true`. `camera`, `region` and the conversions return
`null` before the view's first layout — there is no meaningful camera for a
zero-sized view yet. `selectAnnotation` / `deselectAnnotation` return `false`
when the id isn't on the map (e.g. racing a rebuild that removed it) and
`selectAnnotation` also for a hidden annotation, so you can tell whether
anything happened. `openLookAround` returns `false` when no Look Around scene
exists for the coordinate, and `removeTileOverlay` when the id isn't on the map.
`takeSnapshot` returns PNG bytes; its `options` mirror
`MKMapSnapshotter.Options`.

Calls run on an internal serial queue — concurrent calls execute in source
order. `controller.dispose()` runs automatically when the owning `MKMapView`
widget unmounts.

### Testing code that uses the controller

`MKMapViewController` is an interface, so the code you write against it is
unit-testable without a platform view. With mockito, where `MapPresenter` stands
for your own code and `dart run build_runner build` generates the mock:

<!-- no-compile -->

```dart
@GenerateNiceMocks([MockSpec<MKMapViewController>()])
void main() {
  test('recenters on the selected stop', () async {
    final controller = MockMKMapViewController();
    when(controller.camera).thenAnswer((_) async => someCamera);

    await MapPresenter(controller).select(stop);

    verify(controller.setCenter(stop.coordinate)).called(1);
  });
}
```

## google_maps_flutter-style helpers

The canonical API is the MapKit mirror above. If you think in
google_maps_flutter terms, the exported `CameraConveniences` extension layers
that dialect on top — implemented purely over the canonical calls, no extra
platform surface:

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

Zoom levels are a Web-Mercator convenience (`MKMapCamera.withZoomLevel` /
`camera.zoomLevel`); MapKit's native unit is `distance` in meters. The
camera-relative helpers throw a `StateError` before the view's first layout, and
`fitCoordinates` throws an `ArgumentError` for an empty list, a negative
`padding` / `minimumSpan`, or a span they widen past what `MKCoordinateSpan`
allows (180° latitude, 360° longitude).

## Errors

Misuse fails loudly, in debug and release alike, close to its cause:

- **Invalid values** throw an `ArgumentError` from the constructor (see
  [Values, ids and updates](map-and-overlays.md#values-ids-and-updates)), or
  when `MKMapView` builds or updates with negative or non-finite
  `layoutMargins`.
- **Callbacks that could never fire** throw an `ArgumentError`: `onTap` without
  `consumeTapEvents`; `onDragStart` / `onDragEnd` without `isDraggable`;
  `onCalloutTap` without `calloutConsumesTapEvents` or without a `title` or
  `subtitle`; `onMapFeatureSelected` without `selectableMapFeatures`.
- **Duplicate ids** in one of `MKMapView`'s sets throw an `ArgumentError` when
  the widget builds or updates.
- **iOS-only settings on macOS** throw a `MapKitUnsupportedPlatformException`
  whose `feature` names the setting.
- **Use after dispose** throws a `MapKitDisposedException` from the controller
  methods you call. Updates `MKMapView` itself had queued are simply dropped.
- **Building on the web**, Safari on an iPhone included, throws a
  `MapKitUnsupportedPlatformException`.

Native failures surface as a `MapKitPlatformException` with a stable `code` plus
the native `message` / `details`:

| Code | When |
| --- | --- |
| `snapshot-failed` | `takeSnapshot` produced no image: a tile overlay's tile failed to load, isn't an image or missed the 60-second deadline, the view needs more than 1024 tiles, a tile can't be projected onto the view, base map loading failed, the view has zero size, or the map was disposed during the snapshot |
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

Errors from declarative content (annotations, overlays, configuration) happen
while `MKMapView` pushes an update, outside any call you await, so they surface
as uncaught errors in the zone — they don't vanish. An exception thrown
synchronously by a callback for a map event (`onTap`, `onSelect`,
`onCameraMove`…) goes to `FlutterError.onError`, in every build mode; an `async`
callback's error goes to the zone like any other unawaited future.

What isn't an error is reported as a value: `openLookAround` returns `false`
when no Look Around scene exists for the coordinate, `selectAnnotation` /
`deselectAnnotation` / `removeTileOverlay` return `false` when the id isn't on
the map, and `camera` / `region` / conversions return `null` before the first
layout. Failures MKMapView reports through its delegate surface as widget
callbacks: `onDidFailToLocateUser` (most commonly missing location permission)
and `onDidFailLoadingMap` (map content failed to load, e.g. offline).

## Under the hood

The Dart↔Swift boundary is generated by
[Pigeon](https://pub.dev/packages/pigeon) direct native interop (`dart:ffi` /
`package:objective_c`) from [`pigeons/messages.dart`](../pigeons/messages.dart),
so every call is type-checked on both sides and unused bindings are tree-shaken
in release builds. Wire types keep a `Platform` prefix so the generated Swift
never shadows real MapKit symbols; public Dart names are restored via
`typedef` (e.g. `MKUserTrackingMode`). Regenerating the bindings is covered in
[CONTRIBUTING.md](../CONTRIBUTING.md).
