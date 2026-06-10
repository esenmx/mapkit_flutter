import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

/// End-to-end check of the pigeon channel against a real MKMapView: the only
/// automated coverage of the Swift wiring (per-view channel suffix, host
/// handler registration, camera/region marshaling).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const applePark = CLLocationCoordinate2D(
    latitude: 37.334922,
    longitude: -122.009033,
  );

  testWidgets('map initializes and the camera round-trips', (tester) async {
    MKMapViewController? controller;
    await tester.pumpWidget(
      MaterialApp(
        home: MKMapView(
          initialCamera: const MKMapCamera(
            centerCoordinate: applePark,
            distance: 1500,
          ),
          onMapCreated: (c) => controller = c,
        ),
      ),
    );

    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (controller == null && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    check(
      controller,
      because: 'platform view never reached onMapCreated',
    ).isNotNull();

    // The visible region becomes meaningful once the view has layout.
    var region = await controller!.region;
    while (region.span.latitudeDelta == 0 &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 250));
      region = await controller!.region;
    }
    check(region.span.latitudeDelta).isGreaterThan(0);
    check(region.center.latitude).isCloseTo(applePark.latitude, 0.05);

    // setCamera → camera round-trip through the host API. MapKit may adjust
    // the exact distance, so assertions stay tolerant.
    await controller!.setCamera(
      const MKMapCamera(centerCoordinate: applePark, distance: 5000),
      animated: false,
    );
    await tester.pump(const Duration(seconds: 1));
    final camera = await controller!.camera;
    check(camera.centerCoordinate.latitude).isCloseTo(applePark.latitude, 0.05);
    check(
      camera.centerCoordinate.longitude,
    ).isCloseTo(applePark.longitude, 0.05);
    check(camera.distance).isGreaterThan(0);
  });
}
