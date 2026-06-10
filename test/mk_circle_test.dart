import 'dart:ui' show Color;

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import '_helpers/fixtures.dart';

void main() {
  group('MKCircle wire mapping', () {
    test('serializes renderer vocabulary', () {
      final platform = const MKCircle(
        id: MKCircleId('radius'),
        center: applePark,
        radius: 750,
        fillColor: Color(0x3300FF00),
        strokeColor: Color(0xFF112233),
        lineWidth: 2,
        zIndex: 1,
      ).toPlatform();

      check(platform.id).equals('radius');
      check(platform.center.latitude).equals(applePark.latitude);
      check(platform.radius).equals(750);
      check(platform.fillColorArgb).equals(0x3300FF00);
      check(platform.strokeColorArgb).equals(0xFF112233);
      check(platform.lineWidth).equals(2);
      check(platform.zIndex).equals(1);
      check(platform.isHidden).isFalse();
    });

    test('rejects a negative radius', () {
      check(
        () => MKCircle(
          id: const MKCircleId('bad'),
          center: applePark,
          radius: -1,
        ),
      ).throws<AssertionError>();
    });
  });

  group('equality', () {
    test('compares by value, ignoring onTap', () {
      check(circle('c')).equals(circle('c'));
      check(circle('c').hashCode).equals(circle('c').hashCode);
      check(circle('c') == circle('c', radius: 1)).isFalse();
    });
  });
}
