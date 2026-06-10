import 'dart:ui' show Color;

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import '_helpers/fixtures.dart';

void main() {
  group('MKPolyline wire mapping', () {
    test('serializes renderer vocabulary', () {
      final platform = const MKPolyline(
        id: MKPolylineId('route'),
        coordinates: [applePark, infiniteLoop],
        strokeColor: Color(0xFF0000FF),
        lineWidth: 4,
        lineCap: .butt,
        lineJoin: .miter,
        lineDashPattern: [6, 3],
        zIndex: 2,
        level: .aboveLabels,
        consumeTapEvents: true,
      ).toPlatform();

      check(platform.id).equals('route');
      check(platform.coordinates).length.equals(2);
      check(platform.strokeColorArgb).equals(0xFF0000FF);
      check(platform.lineWidth).equals(4);
      check(platform.lineCap).equals(CGLineCap.butt);
      check(platform.lineJoin).equals(CGLineJoin.miter);
      check(platform.lineDashPattern).isNotNull();
      check(platform.lineDashPattern!).deepEquals([6, 3]);
      check(platform.zIndex).equals(2);
      check(platform.level).equals(MKOverlayLevel.aboveLabels);
      check(platform.consumeTapEvents).isTrue();
      check(platform.isGeodesic).isFalse();
      check(platform.isHidden).isFalse();
    });

    test('defaults mirror MKOverlayPathRenderer', () {
      final platform = polyline('p').toPlatform();
      check(platform.lineCap).equals(CGLineCap.round);
      check(platform.lineJoin).equals(CGLineJoin.round);
      check(platform.lineDashPattern).isNull();
      check(platform.gradientColorsArgb).isNull();
    });

    test('gradient colors serialize as ARGB32 when present', () {
      final platform = const MKPolyline(
        id: MKPolylineId('g'),
        coordinates: [applePark, infiniteLoop],
        gradientColors: [Color(0xFFFF0000), Color(0xFF00FF00)],
      ).toPlatform();
      check(platform.gradientColorsArgb).isNotNull();
      check(platform.gradientColorsArgb!).deepEquals([0xFFFF0000, 0xFF00FF00]);
    });
  });

  group('MKPolyline.geodesic', () {
    test('flags the wire payload without mutating coordinates', () {
      final platform = const MKPolyline.geodesic(
        id: MKPolylineId('arc'),
        coordinates: [applePark, infiniteLoop],
      ).toPlatform();
      check(platform.isGeodesic).isTrue();
      check(platform.coordinates).length.equals(2);
    });

    test('copyWith preserves geodesic-ness', () {
      const arc = MKPolyline.geodesic(
        id: MKPolylineId('arc'),
        coordinates: [applePark, infiniteLoop],
      );
      check(arc.copyWith(lineWidth: 2).isGeodesic).isTrue();
      check(polyline('p').copyWith(lineWidth: 2).isGeodesic).isFalse();
    });

    test('straight and geodesic lines compare unequal', () {
      final straight = polyline('p');
      const arc = MKPolyline.geodesic(
        id: MKPolylineId('p'),
        coordinates: [applePark, infiniteLoop],
      );
      check(straight == arc).isFalse();
    });
  });

  group('equality', () {
    test('compares coordinates and dash pattern by content', () {
      check(
        const MKPolyline(
          id: MKPolylineId('p'),
          coordinates: [applePark],
          lineDashPattern: [1, 2],
        ),
      ).equals(
        const MKPolyline(
          id: MKPolylineId('p'),
          coordinates: [applePark],
          lineDashPattern: [1, 2],
        ),
      );
      check(
        polyline('p') == polyline('p').copyWith(lineDashPattern: const [1]),
      ).isFalse();
    });
  });
}
