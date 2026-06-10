import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

void main() {
  group('MKPointOfInterestFilter wire mapping', () {
    test('includingAll maps to the all mode with no categories', () {
      final platform = MKPointOfInterestFilter.includingAll.toPlatform();
      check(platform.mode).equals(PlatformPOIMode.all);
      check(platform.categories).isEmpty();
    });

    test('excludingAll maps to the none mode', () {
      final platform = MKPointOfInterestFilter.excludingAll.toPlatform();
      check(platform.mode).equals(PlatformPOIMode.none);
      check(platform.categories).isEmpty();
    });

    test('including carries its categories', () {
      final platform = const MKPointOfInterestFilter.including([
        .cafe,
        .museum,
      ]).toPlatform();
      check(platform.mode).equals(PlatformPOIMode.including);
      check(platform.categories).deepEquals([
        MKPointOfInterestCategory.cafe,
        MKPointOfInterestCategory.museum,
      ]);
    });

    test('excluding carries its categories', () {
      final platform = const MKPointOfInterestFilter.excluding([
        .nightlife,
      ]).toPlatform();
      check(platform.mode).equals(PlatformPOIMode.excluding);
      check(
        platform.categories,
      ).deepEquals([MKPointOfInterestCategory.nightlife]);
    });
  });

  group('MKPointOfInterestFilter equality', () {
    test('same categories compare equal', () {
      check(
        const MKPointOfInterestFilter.including([.cafe]),
      ).equals(const MKPointOfInterestFilter.including([.cafe]));
    });

    test('including and excluding never compare equal', () {
      check(
        const MKPointOfInterestFilter.including([.cafe]) ==
            const MKPointOfInterestFilter.excluding([.cafe]),
      ).isFalse();
    });
  });
}
