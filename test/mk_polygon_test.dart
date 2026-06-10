import 'dart:ui' show Color;

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import '_helpers/fixtures.dart';

void main() {
  group('MKPolygon wire mapping', () {
    test('serializes interior polygons ring by ring', () {
      final platform = const MKPolygon(
        id: MKPolygonId('zone'),
        coordinates: [
          CLLocationCoordinate2D(latitude: 0, longitude: 0),
          CLLocationCoordinate2D(latitude: 0, longitude: 10),
          CLLocationCoordinate2D(latitude: 10, longitude: 10),
        ],
        interiorPolygons: [
          [
            CLLocationCoordinate2D(latitude: 2, longitude: 2),
            CLLocationCoordinate2D(latitude: 2, longitude: 4),
            CLLocationCoordinate2D(latitude: 4, longitude: 4),
          ],
        ],
        fillColor: Color(0x6600FF00),
        strokeColor: Color(0xFF112233),
        lineWidth: 3,
      ).toPlatform();

      check(platform.id).equals('zone');
      check(platform.coordinates).length.equals(3);
      check(platform.interiorPolygons).length.equals(1);
      check(platform.interiorPolygons.single).length.equals(3);
      check(platform.fillColorArgb).equals(0x6600FF00);
      check(platform.strokeColorArgb).equals(0xFF112233);
      check(platform.lineWidth).equals(3);
      check(platform.isHidden).isFalse();
    });
  });

  group('equality', () {
    test('compares rings by content', () {
      check(polygon('z')).equals(polygon('z'));
      check(polygon('z').hashCode).equals(polygon('z').hashCode);
      check(
        polygon('z') ==
            polygon('z').copyWith(
              interiorPolygons: const [
                [
                  CLLocationCoordinate2D(latitude: 1, longitude: 1),
                  CLLocationCoordinate2D(latitude: 1, longitude: 2),
                  CLLocationCoordinate2D(latitude: 2, longitude: 2),
                ],
              ],
            ),
      ).isFalse();
    });
  });
}
