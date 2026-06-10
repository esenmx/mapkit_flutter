import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('MKStandardMapConfiguration', () {
    test('defaults mirror MKStandardMapConfiguration', () {
      const config = MKStandardMapConfiguration();
      check(config.elevationStyle).equals(MKMapElevationStyle.flat);
      check(config.emphasisStyle).equals(MKMapEmphasisStyle.standard);
      check(
        config.pointOfInterestFilter,
      ).equals(MKPointOfInterestFilter.includingAll);
      check(config.showsTraffic).isFalse();
    });

    test('equality covers every field', () {
      check(
        const MKStandardMapConfiguration(showsTraffic: true),
      ).equals(const MKStandardMapConfiguration(showsTraffic: true));
      check(
        const MKStandardMapConfiguration(showsTraffic: true) ==
            const MKStandardMapConfiguration(),
      ).isFalse();
      check(
        const MKStandardMapConfiguration(emphasisStyle: .muted) ==
            const MKStandardMapConfiguration(),
      ).isFalse();
    });
  });

  group('MKHybridMapConfiguration', () {
    test('equality covers traffic and POI filter', () {
      check(
        const MKHybridMapConfiguration(pointOfInterestFilter: .excludingAll),
      ).equals(
        const MKHybridMapConfiguration(pointOfInterestFilter: .excludingAll),
      );
      check(
        const MKHybridMapConfiguration(showsTraffic: true) ==
            const MKHybridMapConfiguration(),
      ).isFalse();
    });
  });

  group('MKImageryMapConfiguration', () {
    test('equality covers elevation', () {
      check(
        const MKImageryMapConfiguration(elevationStyle: .realistic),
      ).equals(const MKImageryMapConfiguration(elevationStyle: .realistic));
      check(
        const MKImageryMapConfiguration() ==
            const MKImageryMapConfiguration(elevationStyle: .realistic),
      ).isFalse();
    });

    test('variants of different kinds never compare equal', () {
      const MKMapConfiguration standard = MKStandardMapConfiguration();
      const MKMapConfiguration imagery = MKImageryMapConfiguration();
      check(standard == imagery).isFalse();
    });
  });
}
