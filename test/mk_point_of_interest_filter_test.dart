import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

void main() {
  group('MKPointOfInterestFilter wire mapping', () {
    test('includingAll maps to the all mode with no categories', () {
      final platform = MKPointOfInterestFilter.includingAll.toPlatform();
      check(platform.mode).equals(.all);
      check(platform.categories).isEmpty();
    });

    test('excludingAll maps to the none mode', () {
      final platform = MKPointOfInterestFilter.excludingAll.toPlatform();
      check(platform.mode).equals(.none);
      check(platform.categories).isEmpty();
    });

    test('including carries its categories', () {
      const filter = MKPointOfInterestFilter.including([.cafe, .museum]);
      final platform = filter.toPlatform();
      check(platform.mode).equals(PlatformPOIMode.including);
      check(platform.categories).deepEquals([
        MKPointOfInterestCategory.cafe,
        MKPointOfInterestCategory.museum,
      ]);
    });

    test('excluding carries its categories', () {
      const filter = MKPointOfInterestFilter.excluding([.nightlife]);
      final platform = filter.toPlatform();
      check(platform.mode).equals(PlatformPOIMode.excluding);
      const expected = [MKPointOfInterestCategory.nightlife];
      check(platform.categories).deepEquals(expected);
    });
  });

  group('MKPointOfInterestFilter equality', () {
    test('same categories compare equal', () {
      const cafe = MKPointOfInterestFilter.including([.cafe]);
      check(cafe).equals(cafe);
    });

    test('including and excluding never compare equal', () {
      check(
        const MKPointOfInterestFilter.including([.cafe]) ==
            const .excluding([.cafe]),
      ).isFalse();
    });
  });
}
