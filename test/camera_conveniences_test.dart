import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

import '_helpers/controller_harness.dart';
import '_helpers/platform_fixtures.dart';
import '_helpers/recorded_call.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ControllerHarness harness;

  setUp(() => harness = ControllerHarness(viewId: 2));
  tearDown(() => harness.dispose());

  group('getZoomLevel', () {
    test('derives the level from the host camera distance', () async {
      harness.host.camera = platformCamera(distance: 591657550.5);
      check(await harness.controller.getZoomLevel()).isCloseTo(1, 1e-9);
      harness.expectCalls(['getCamera']);
    });
  });

  group('zoomTo', () {
    test('reads the camera, then sets it at the requested level', () async {
      await harness.controller.zoomTo(10, animated: false);
      harness.expectCalls(['getCamera', 'setCamera']);
      final (camera, animated) = harness.expectSetCamera();
      check(camera.distance).isCloseTo(591657550.5 / 512, 1e-6);
      check(animated).isFalse();
    });

    test('preserves center, heading, and pitch', () async {
      harness.host.camera = platformCamera(
        latitude: 10,
        longitude: 20,
        distance: 5000,
        heading: 45,
        pitch: 30,
      );
      await harness.controller.zoomTo(12);
      final (camera, _) = harness.expectSetCamera();
      check(camera.centerCoordinate.latitude).equals(10);
      check(camera.heading).equals(45);
      check(camera.pitch).equals(30);
    });
  });

  group('zoomBy', () {
    test('halves the distance per level zoomed in', () async {
      await harness.controller.zoomBy(1);
      harness.expectCalls(['getCamera', 'setCamera']);
      check(harness.expectSetCamera().$1.distance).isCloseTo(500, 1e-9);
    });

    test('zoomIn and zoomOut are one level each way', () async {
      await harness.controller.zoomIn();
      check(harness.expectSetCamera().$1.distance).isCloseTo(500, 1e-9);

      harness.host.calls.clear();
      await harness.controller.zoomOut();
      check(harness.expectSetCamera().$1.distance).isCloseTo(2000, 1e-9);
    });
  });

  group('scrollBy', () {
    test('converts the shifted center point back to a coordinate', () async {
      harness.host
        ..point = platformPoint(100, 200)
        ..coordinate = platformCoord(5, 6);

      await harness.controller.scrollBy(50, -30, animated: false);

      harness.expectCalls([
        'getCamera',
        'convertToPoint',
        'convertToCoordinate',
        'setCenter',
      ]);
      final shifted = harness.host.calls.requireArgsAt<PlatformPoint>(2);
      check(shifted.x).equals(150);
      check(shifted.y).equals(170);
      final (center, animated) = harness.expectSetCenter();
      check(center.latitude).equals(5);
      check(animated).isFalse();
    });

    test('is a no-op while the view has no layout', () async {
      harness.host.point = null;
      await harness.controller.scrollBy(10, 10);
      harness.expectCalls(['getCamera', 'convertToPoint']);
    });
  });

  group('fitCoordinates', () {
    test('sets the containing region', () async {
      await harness.controller.fitCoordinates(const [
        CLLocationCoordinate2D(latitude: 10, longitude: 20),
        CLLocationCoordinate2D(latitude: 30, longitude: 40),
      ], animated: false);
      harness.expectCalls(['setRegion']);
      final (region, _) = harness.expectSetRegion();
      check(region.center.latitude).equals(20);
      check(region.span.longitudeDelta).equals(20);
    });

    test('is a no-op for an empty set', () async {
      await harness.controller.fitCoordinates(const []);
      check(harness.host.calls).isEmpty();
    });
  });
}
