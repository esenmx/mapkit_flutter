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

Run it on an iOS simulator or device:

```sh
flutter run
```

The integration smoke test (real `MKMapView`, real pigeon channel):

```sh
flutter test integration_test/ -d "iPhone 16"
```
