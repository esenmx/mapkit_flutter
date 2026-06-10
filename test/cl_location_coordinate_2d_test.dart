import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('CLLocationCoordinate2D', () {
    test('equality is value-based', () {
      const a = CLLocationCoordinate2D(latitude: 10, longitude: 20);
      const b = CLLocationCoordinate2D(latitude: 10, longitude: 20);
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('clamps latitude to [-90, 90]', () {
      check(
        const CLLocationCoordinate2D(latitude: 91, longitude: 0).latitude,
      ).equals(90);
      check(
        const CLLocationCoordinate2D(latitude: -120, longitude: 0).latitude,
      ).equals(-90);
    });

    test('wraps longitude to [-180, 180)', () {
      check(
        const CLLocationCoordinate2D(latitude: 0, longitude: 190).longitude,
      ).equals(-170);
      check(
        const CLLocationCoordinate2D(latitude: 0, longitude: -190).longitude,
      ).equals(170);
      check(
        const CLLocationCoordinate2D(latitude: 0, longitude: 180).longitude,
      ).equals(-180);
      check(
        const CLLocationCoordinate2D(latitude: 0, longitude: 540).longitude,
      ).equals(-180);
    });

    test('round-trips through the platform type', () {
      const original = CLLocationCoordinate2D(latitude: 37.5, longitude: -122);
      final platform = original.toPlatform();
      check(platform.latitude).equals(37.5);
      check(platform.longitude).equals(-122);
      check(CLLocationCoordinate2D.fromPlatform(platform)).equals(original);
    });

    test('Coordinate is an alias for the full Apple symbol', () {
      const alias = CLLocationCoordinate2D(latitude: 1, longitude: 2);
      check(
        alias,
      ).equals(const CLLocationCoordinate2D(latitude: 1, longitude: 2));
    });
  });
}
