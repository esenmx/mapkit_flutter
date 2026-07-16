import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('MKCoordinateRegion.containing', () {
    test('returns null for no coordinates', () {
      check(MKCoordinateRegion.containing(const [])).isNull();
    });

    test('single coordinate yields a zero span centered on it', () {
      const point = CLLocationCoordinate2D(latitude: 10, longitude: 20);
      final region = MKCoordinateRegion.containing(const [point]);
      check(region).isNotNull();
      check(region!.center).equals(point);
      check(
        region.span,
      ).equals(const MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
    });

    test('spans the extremes with the midpoint as center', () {
      final region = MKCoordinateRegion.containing(const [
        CLLocationCoordinate2D(latitude: 10, longitude: 20),
        CLLocationCoordinate2D(latitude: 30, longitude: 40),
        CLLocationCoordinate2D(latitude: 15, longitude: 25),
      ]);
      check(region).isNotNull();
      check(
        region!.center,
      ).equals(const CLLocationCoordinate2D(latitude: 20, longitude: 30));
      check(
        region.span,
      ).equals(const MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20));
    });
  });

  group('MKCoordinateRegion.contains', () {
    const region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 10, longitude: 20),
      span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 6),
    );

    test('accepts the center and edge coordinates', () {
      check(
        region.contains(
          const CLLocationCoordinate2D(latitude: 10, longitude: 20),
        ),
      ).isTrue();
      check(
        region.contains(
          const CLLocationCoordinate2D(latitude: 12, longitude: 23),
        ),
      ).isTrue();
    });

    test('rejects coordinates past either delta', () {
      check(
        region.contains(
          const CLLocationCoordinate2D(latitude: 12.1, longitude: 20),
        ),
      ).isFalse();
      check(
        region.contains(
          const CLLocationCoordinate2D(latitude: 10, longitude: 23.1),
        ),
      ).isFalse();
    });

    test('handles regions spanning the antimeridian', () {
      const wrapped = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 179.5),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 2),
      );
      check(
        wrapped.contains(
          const CLLocationCoordinate2D(latitude: 0, longitude: -179.8),
        ),
      ).isTrue();
      check(
        wrapped.contains(
          const CLLocationCoordinate2D(latitude: 0, longitude: 178),
        ),
      ).isFalse();
    });
  });

  group('MKCoordinateRegion wire format', () {
    test('round-trips through the platform type', () {
      const region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 10, longitude: 20),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2),
      );
      final platform = region.toPlatform();
      check(platform.center.latitude).equals(10);
      check(platform.span.longitudeDelta).equals(2);
      check(MKCoordinateRegion.fromPlatform(platform)).equals(region);
    });
  });
}
