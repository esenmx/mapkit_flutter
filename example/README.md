# mapkit_flutter example

A single-page demo exercising the plugin surface — annotations with glyph
markers, a geodesic gradient polyline, a dashed polyline, a polygon with an
interior cutout, a circle, the three `MKMapConfiguration` styles, fit-to-
annotations, Look Around, and snapshots. See [`lib/main.dart`](lib/main.dart).

```dart
MKMapView(
  initialCamera: MKMapCamera.withZoomLevel(
    centerCoordinate: CLLocationCoordinate2D(
      latitude: 37.334922,
      longitude: -122.009033,
    ),
    zoomLevel: 14,
  ),
  annotations: {
    MKPointAnnotation(
      id: MKAnnotationId('apple-park'),
      coordinate: CLLocationCoordinate2D(
        latitude: 37.334922,
        longitude: -122.009033,
      ),
      title: 'Apple Park',
    ),
  },
  onMapCreated: (MKMapViewController controller) {
    // controller.setCamera / setRegion / region / takeSnapshot ...
  },
)
```

Run it on an iOS simulator or macOS (`flutter run -d macos`).

The example builds through Swift Package Manager, which resolves the plugin by
its directory name: the repository checkout must be a directory named
`mapkit_flutter` (e.g. `git clone https://github.com/esenmx/mapkit_flutter.git`).

Integration tests (real `MKMapView`, real pigeon channel) run one file per
invocation, on macOS or on a simulator:

```sh
flutter test integration_test/<file>.dart -d macos
flutter test integration_test/<file>.dart -d "iPhone 16"
```

Native tests (XCTest against the plugin's Swift code):

```sh
flutter build macos --config-only && xcodebuild test -workspace macos/Runner.xcworkspace -scheme Runner -destination 'platform=macOS'
```
