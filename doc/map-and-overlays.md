# Map style, annotations and overlays

## A page with a pin

A real page usually keeps the controller that `onMapCreated` hands over, for
imperative calls such as moving the camera:

```dart
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:material_ui/material_ui.dart';

class const MapPage({super.key}) extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static final _applePark = CLLocationCoordinate2D(
    latitude: 37.334922,
    longitude: -122.009033,
  );

  MKMapViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apple Park')),
      body: MKMapView(
        initialCamera: MKMapCamera(
          centerCoordinate: _applePark,
          distance: 1500, // MKMapCamera.centerCoordinateDistance, meters
        ),
        annotations: {
          MKPointAnnotation(
            id: const MKAnnotationId('apple-park'),
            coordinate: _applePark,
            title: 'Apple Park',
            subtitle: 'One Apple Park Way',
          ),
        },
        onMapCreated: (controller) => _controller = controller,
        // Recenter on the tapped point.
        onTap: (coordinate) => _controller?.setCenter(coordinate),
      ),
    );
  }
}
```

## Values, ids and updates

Value types validate in every build mode and throw an `ArgumentError` for input
MapKit can't represent — a latitude outside `[-90, 90]` (swapped arguments), a
non-finite number, a negative `lineWidth`, `alpha` outside `[0, 1]`, a camera
`pitch` outside `[0, 90)`, a zoom range whose minimum exceeds its maximum. That
is why those types have no `const` constructor; ids, marker icons, regions, map
configurations and snapshot options do. Polylines, polygons and
point-of-interest filters keep their own unmodifiable copy of the lists you
pass, so changing a list later never changes the value. Longitude wraps into
`[-180, 180)` like MapKit. `Coordinate` is an exported alias for
`CLLocationCoordinate2D`; if another package also exports a `Coordinate`, `hide`
it on import.

Content is declarative: on every rebuild, `MKMapView` diffs each set by id. A
new id is added, a changed object with the same id is updated, and an id that
left the set is removed from the map. The diff runs against what the map last
accepted, so you can build a new set on every rebuild or change one in place and
call `setState`. A batch MapKit rejects, say for an undecodable icon, fails as a
whole; once you change the set, everything it held goes out again. Ids must be
unique per kind; two annotations (or two polylines…) sharing an id throw when
`MKMapView` builds.

Models override `==`, so they can't be used in `const {…}` set literals — build
the set without `const`. `copyWith` clears a nullable field when you pass `null`
explicitly:

```dart
MKPointAnnotation untitled(MKPointAnnotation annotation) =>
    annotation.copyWith(title: null);
```

## Map style and controls

The widget mirrors `MKMapView`. The base style is a sealed
`preferredConfiguration` (exactly `MKMapView.preferredConfiguration`);
view-level switches are direct parameters with their `MKMapView` property names.
Here the function's parameters stand in for your app's state:

```dart
MKMapView campusMap({
  required MKMapCamera camera,
  required MKCoordinateRegion campus,
  required MKUserTrackingMode trackingMode,
  required ValueChanged<MKUserTrackingMode> onTrackingModeChanged,
}) {
  return MKMapView(
    initialCamera: camera,
    preferredConfiguration: MKStandardMapConfiguration(
      elevationStyle: MKMapElevationStyle.realistic,
      // `standard` is Apple's `.default`, a reserved word in Dart.
      emphasisStyle: MKMapEmphasisStyle.muted,
      pointOfInterestFilter: MKPointOfInterestFilter.including(const [
        MKPointOfInterestCategory.cafe,
        MKPointOfInterestCategory.park,
      ]),
      showsTraffic: true,
    ),
    // MKHybridMapConfiguration() / MKImageryMapConfiguration() likewise.
    isRotateEnabled: false,
    isPitchEnabled: false,
    showsCompass: false,
    showsScale: true,
    showsUserLocation: true,
    showsUserTrackingButton: true,
    // Applied when it changes. MapKit drops back to `none` when the user
    // pans: store the reported mode so the next rebuild matches.
    userTrackingMode: trackingMode,
    onUserTrackingModeChanged: onTrackingModeChanged,
    cameraZoomRange: MKCameraZoomRange(
      minCenterCoordinateDistance: 500, // meters
      maxCenterCoordinateDistance: 100000,
    ),
    cameraBoundary: campus, // keeps the camera center inside
    // iOS only: throws on macOS.
    selectableMapFeatures: const {MKMapFeatureOptions.pointsOfInterest},
    onMapFeatureSelected: (feature) => debugPrint('Selected ${feature.title}'),
    layoutMargins: const EdgeInsets.only(bottom: 240),
  );
}
```

By default all four gestures (zoom, scroll, rotate, pitch) are enabled and the
compass is shown; the scale, the user's location and the tracking button are
hidden.

## Annotations

`MKPointAnnotation` merges the annotation (`coordinate`, `title`, `subtitle`)
with its `MKAnnotationView` presentation (`alpha`, `isDraggable`, `zPriority`,
`clusteringIdentifier`…) — Flutter is declarative, so there is no separate view
object.

```dart
Future<Set<MKPointAnnotation>> places({
  required BuildContext context,
  required Coordinate home,
  required Coordinate cafe,
  required Coordinate shop,
  required Coordinate friend,
  required Coordinate applePark,
  required Uint8List avatarPng,
}) async {
  final pin = await MKAnnotationIcon.asset('assets/pin.png');
  return {
    // System balloon marker (MKMarkerAnnotationView).
    MKPointAnnotation(id: const MKAnnotationId('home'), coordinate: home),

    // Tinted marker with an SF Symbol glyph.
    MKPointAnnotation(
      id: const MKAnnotationId('cafe'),
      coordinate: cafe,
      icon: const MKAnnotationIcon.marker(
        markerTintColor: Colors.brown,
        systemImage: 'cup.and.saucer.fill',
        glyphTintColor: Colors.white,
      ),
    ),

    // Custom image from an asset, loaded above.
    MKPointAnnotation(
      id: const MKAnnotationId('shop'),
      coordinate: shop,
      icon: pin,
    ),

    // Fully custom marker: the PNG bytes of a rendered Flutter widget
    // (e.g. captured with RenderRepaintBoundary.toImage).
    MKPointAnnotation(
      id: const MKAnnotationId('friend'),
      coordinate: friend,
      icon: MKAnnotationIcon.image(avatarPng),
    ),

    // Callout, selection and drag.
    MKPointAnnotation(
      id: const MKAnnotationId('apple-park'),
      coordinate: applePark,
      title: 'Apple Park',
      subtitle: 'One Apple Park Way',
      calloutConsumesTapEvents: true, // iOS only; onCalloutTap needs it
      onCalloutTap: () => Navigator.pushNamed(context, '/details'),
      onSelect: () => debugPrint('selected'), // tap or selectAnnotation
      onDeselect: () => debugPrint('deselected'),
      isDraggable: true,
      onDragEnd: (coordinate) => debugPrint('dropped at $coordinate'),
    ),
  };
}
```

Annotations sharing a `clusteringIdentifier` cluster natively when they crowd.
Image bytes the platform can't decode, or an SF Symbol name it doesn't know,
fail the map update with a `MapKitPlatformException` (`invalid-icon`) instead of
rendering an invisible or plain pin.

## Overlays

`MKPolyline`, `MKPolygon` and `MKCircle` each merge in their renderer's
properties: `strokeColor` and `lineWidth` on all three, `fillColor` on polygons
and circles, `lineCap`, `lineJoin`, `lineDashPattern` and `gradientColors` on
polylines. Caps and joins (`CGLineCap`, `CGLineJoin`) default to round, as in
MapKit's path renderers.

```dart
MKMapView overlays({
  required MKMapCamera camera,
  required List<Coordinate> route,
  required Coordinate sfo,
  required Coordinate nrt,
  required List<Coordinate> zone,
  required List<Coordinate> courtyard,
  required Coordinate store,
}) {
  return MKMapView(
    initialCamera: camera,
    polylines: {
      MKPolyline(
        id: const MKPolylineId('route'),
        coordinates: route,
        strokeColor: Colors.blue,
        lineWidth: 6,
        lineDashPattern: const [6, 3], // dash and gap lengths in points
        lineCap: CGLineCap.butt, // flat dash ends
        level: MKOverlayLevel.aboveLabels,
        consumeTapEvents: true, // capture taps…
        onTap: () => debugPrint('route'), // …to receive them
      ),
      // Great-circle path, densified natively by MKGeodesicPolyline.
      MKPolyline.geodesic(
        id: const MKPolylineId('sfo-nrt'),
        coordinates: [sfo, nrt],
        lineWidth: 4,
        // Two or more colors; replaces strokeColor.
        gradientColors: const [Colors.green, Colors.red],
      ),
    },
    polygons: {
      MKPolygon(
        id: const MKPolygonId('zone'),
        coordinates: zone,
        interiorPolygons: [courtyard], // holes, as in MKPolygon
        fillColor: Colors.red.withValues(alpha: 0.3),
        strokeColor: Colors.red,
        lineWidth: 2,
      ),
    },
    circles: {
      MKCircle(
        id: const MKCircleId('radius'),
        center: store,
        radius: 500, // meters
      ),
    },
  );
}
```

Only overlays with `consumeTapEvents: true` capture taps; the top-most capturing
overlay under a tap fires its `onTap`, and the tap doesn't reach the map's
`onTap`. Setting `onTap` without `consumeTapEvents` throws an `ArgumentError` —
it could never fire. Polyline hit-testing covers the visible stroke (half the
`lineWidth`, at least 8 points).

### Tile overlays

Tile overlays go through the controller (`MKTileOverlay(urlTemplate:)`
semantics, with the renderer's `alpha` merged in):

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

Adding an id that is already on the map throws (`duplicate-id`); remove it first
to replace it. `removeTileOverlay` returns `false` when the id isn't on the map.

Snapshots include tile overlays. `takeSnapshot` fetches the visible tiles with
the overlay's own `MKTileOverlay.loadTile`, each at the zoom its on-screen size
calls for, then draws them in the map's overlay order with their `alpha`. A
snapshot fails with `snapshot-failed` when a tile can't be fetched or isn't an
image, and that includes a server's 404 page, so give sparse sources a blank
tile instead. It also fails when tiles don't arrive within 60 seconds, and when
a view needs more than 1024 tiles across its overlays. At the default `tileSize`
of 256, MapKit's steepest camera takes about 50 tiles on a phone and 300 on a
2560-point window, so that takes a very small `tileSize` or several overlays on
a large window.

What a snapshot can't match on the live map:

- `MKMapSnapshotter` bakes Apple's labels and 3D buildings into its base map, so
  even an `aboveRoads` overlay lies flat on top of them.
- With `canReplaceMapContent`, the snapshot leaves out the base map and is
  transparent where no opaque tile covers it.
- A steep camera asks your source for low zooms toward the horizon, down to zoom
  0, and distant tiles look softer than near ones. MapKit's pitch cap puts the
  ground's horizon at the top of the view, so tiles reach it, covering the band
  where Apple's own base map has already faded into sky.
- Tile grids end at the Mercator world's edge, about 85.05° north and south.
  Past that the base map shows through, which a steep camera at high latitudes
  can bring into view.
- Past `maximumZ` the highest tiles are upscaled, however close the camera
  comes. Where a tile would fall below `minimumZ` the overlay has nothing to
  draw and the base map shows through, which under a steep camera means the far
  part of the view.
