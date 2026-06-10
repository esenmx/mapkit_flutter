import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import '_helpers/fixtures.dart';

void main() {
  group('MKMapCamera', () {
    test('equality is value-based', () {
      const a = MKMapCamera(
        centerCoordinate: applePark,
        distance: 1200,
        heading: 90,
        pitch: 45,
      );
      const b = MKMapCamera(
        centerCoordinate: applePark,
        distance: 1200,
        heading: 90,
        pitch: 45,
      );
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('copyWith replaces only the given fields', () {
      final moved = sampleCamera.copyWith(distance: 600, heading: 180);
      check(moved.centerCoordinate).equals(sampleCamera.centerCoordinate);
      check(moved.distance).equals(600);
      check(moved.heading).equals(180);
      check(moved.pitch).equals(sampleCamera.pitch);
    });

    test('rejects a non-positive distance', () {
      check(
        () => MKMapCamera(centerCoordinate: applePark, distance: 0),
      ).throws<AssertionError>();
    });

    test('round-trips through the platform type', () {
      const camera = MKMapCamera(
        centerCoordinate: applePark,
        distance: 1200,
        heading: 90,
        pitch: 45,
      );
      final platform = camera.toPlatform();
      check(platform.distance).equals(1200);
      check(platform.heading).equals(90);
      check(MKMapCamera.fromPlatform(platform)).equals(camera);
    });
  });

  group('zoom-level convenience', () {
    test('zoom level 1 anchors at the base distance', () {
      final camera = MKMapCamera.withZoomLevel(
        centerCoordinate: applePark,
        zoomLevel: 1,
      );
      check(camera.distance).equals(591657550.5);
    });

    test('each level halves the distance', () {
      final z3 = MKMapCamera.withZoomLevel(
        centerCoordinate: applePark,
        zoomLevel: 3,
      );
      final z4 = MKMapCamera.withZoomLevel(
        centerCoordinate: applePark,
        zoomLevel: 4,
      );
      check(z3.distance / z4.distance).isCloseTo(2, 1e-9);
    });

    test('zoomLevel inverts withZoomLevel', () {
      for (final level in const [1.0, 5.5, 15.0, 20.0]) {
        final camera = MKMapCamera.withZoomLevel(
          centerCoordinate: applePark,
          zoomLevel: level,
        );
        check(camera.zoomLevel).isCloseTo(level, 1e-9);
      }
    });

    test('withZoomLevel preserves heading and pitch', () {
      final camera = MKMapCamera.withZoomLevel(
        centerCoordinate: applePark,
        zoomLevel: 14,
        heading: 33,
        pitch: 12,
      );
      check(camera.heading).equals(33);
      check(camera.pitch).equals(12);
    });
  });
}
