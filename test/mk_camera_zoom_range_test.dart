import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('MKCameraZoomRange', () {
    test('defaults to unbounded', () {
      const range = MKCameraZoomRange();
      check(range.minCenterCoordinateDistance).isNull();
      check(range.maxCenterCoordinateDistance).isNull();
    });

    test('equality is value-based', () {
      const a = MKCameraZoomRange(
        minCenterCoordinateDistance: 500,
        maxCenterCoordinateDistance: 100000,
      );
      const b = MKCameraZoomRange(
        minCenterCoordinateDistance: 500,
        maxCenterCoordinateDistance: 100000,
      );
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('rejects min above max', () {
      check(
        () => MKCameraZoomRange(
          minCenterCoordinateDistance: 2,
          maxCenterCoordinateDistance: 1,
        ),
      ).throws<AssertionError>();
    });

    test('serializes both distances', () {
      const range = MKCameraZoomRange(
        minCenterCoordinateDistance: 500,
        maxCenterCoordinateDistance: 100000,
      );
      final platform = range.toPlatform();
      check(platform.minCenterCoordinateDistance).equals(500);
      check(platform.maxCenterCoordinateDistance).equals(100000);
    });
  });
}
