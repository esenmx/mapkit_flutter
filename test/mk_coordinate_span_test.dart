import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('MKCoordinateSpan', () {
    test('equality is value-based', () {
      const a = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2);
      const b = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2);
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('rejects negative deltas', () {
      MKCoordinateSpan span(double lat, double lng) =>
          MKCoordinateSpan(latitudeDelta: lat, longitudeDelta: lng);
      check(() => span(-1, 0)).throws<AssertionError>();
      check(() => span(0, -1)).throws<AssertionError>();
    });

    test('round-trips through the platform type', () {
      const original = MKCoordinateSpan(
        latitudeDelta: 1.5,
        longitudeDelta: 2.5,
      );
      final platform = original.toPlatform();
      check(platform.latitudeDelta).equals(1.5);
      check(platform.longitudeDelta).equals(2.5);
      check(MKCoordinateSpan.fromPlatform(platform)).equals(original);
    });

    test('toString representation', () {
      const span = MKCoordinateSpan(latitudeDelta: 1.2, longitudeDelta: 3.4);
      check(span.toString()).equals('MKCoordinateSpan(1.2, 3.4)');
    });
  });
}
