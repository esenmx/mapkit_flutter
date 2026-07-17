import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('MKMapSnapshotOptions', () {
    test('defaults are all true', () {
      const options = MKMapSnapshotOptions();
      check(options.showsBuildings).isTrue();
      check(options.showsPointsOfInterest).isTrue();
      check(options.showsAnnotations).isTrue();
      check(options.showsOverlays).isTrue();
    });

    test('custom values are retained', () {
      const options = MKMapSnapshotOptions(
        showsBuildings: false,
        showsPointsOfInterest: false,
        showsAnnotations: false,
        showsOverlays: false,
      );
      check(options.showsBuildings).isFalse();
      check(options.showsPointsOfInterest).isFalse();
      check(options.showsAnnotations).isFalse();
      check(options.showsOverlays).isFalse();
    });

    test('toPlatform() correctly maps to PlatformSnapshotOptions', () {
      const options = MKMapSnapshotOptions(
        showsBuildings: false,
        showsAnnotations: false,
      );
      final platform = options.toPlatform();
      check(platform.showsBuildings).isFalse();
      check(platform.showsPointsOfInterest).isTrue();
      check(platform.showsAnnotations).isFalse();
      check(platform.showsOverlays).isTrue();
    });

    test('equality checks all fields', () {
      const options1 = MKMapSnapshotOptions();
      const options2 = MKMapSnapshotOptions();
      const options3 = MKMapSnapshotOptions(showsBuildings: false);
      const options4 = MKMapSnapshotOptions(showsPointsOfInterest: false);
      const options5 = MKMapSnapshotOptions(showsAnnotations: false);
      const options6 = MKMapSnapshotOptions(showsOverlays: false);

      check(options1).equals(options2);
      check(options1 == options3).isFalse();
      check(options1 == options4).isFalse();
      check(options1 == options5).isFalse();
      check(options1 == options6).isFalse();
    });

    test('hashCode reflects all fields', () {
      const options1 = MKMapSnapshotOptions();
      const options2 = MKMapSnapshotOptions();
      const options3 = MKMapSnapshotOptions(showsBuildings: false);

      check(options1.hashCode).equals(options2.hashCode);
      check(options1.hashCode == options3.hashCode).isFalse();
    });

    test('toString() contains expected property states', () {
      const options = MKMapSnapshotOptions(
        showsBuildings: false,
        showsAnnotations: false,
      );
      check(options.toString()).contains('showsBuildings: false');
      check(options.toString()).contains('showsPointsOfInterest: true');
      check(options.toString()).contains('showsAnnotations: false');
      check(options.toString()).contains('showsOverlays: true');
    });
  });
}
