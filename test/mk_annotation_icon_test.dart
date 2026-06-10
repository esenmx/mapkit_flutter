import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

void main() {
  group('MKAnnotationIcon.marker', () {
    test('plain marker serializes with no styling', () {
      final platform = const MKAnnotationIcon.marker().toPlatform();
      check(platform.type).equals(PlatformAnnotationIconType.marker);
      check(platform.markerTintArgb).isNull();
      check(platform.glyphText).isNull();
      check(platform.glyphSystemImage).isNull();
      check(platform.glyphTintArgb).isNull();
      check(platform.imageBytes).isNull();
    });

    test('serializes MKMarkerAnnotationView styling as ARGB32', () {
      final platform = const MKAnnotationIcon.marker(
        markerTintColor: Color(0xFF112233),
        glyphText: 'HQ',
        systemImage: 'star.fill',
        glyphTintColor: Color(0xFFFFFFFF),
      ).toPlatform();
      check(platform.markerTintArgb).equals(0xFF112233);
      check(platform.glyphText).equals('HQ');
      check(platform.glyphSystemImage).equals('star.fill');
      check(platform.glyphTintArgb).equals(0xFFFFFFFF);
      check(platform.imageBytes).isNull();
    });
  });

  group('MKAnnotationIcon.image', () {
    test('serializes raw bytes', () {
      final png = Uint8List.fromList([1, 2, 3]);
      final platform = MKAnnotationIcon.image(png).toPlatform();
      check(platform.type).equals(PlatformAnnotationIconType.image);
      check(platform.imageBytes).isNotNull();
      check(platform.imageBytes!).deepEquals(png);
      check(platform.markerTintArgb).isNull();
    });
  });

  group('equality', () {
    test('markers compare by full styling', () {
      check(
        const MKAnnotationIcon.marker(markerTintColor: Color(0xFF112233)),
      ).equals(
        const MKAnnotationIcon.marker(markerTintColor: Color(0xFF112233)),
      );
      check(
        const MKAnnotationIcon.marker(markerTintColor: Color(0xFF112233)) ==
            const MKAnnotationIcon.marker(),
      ).isFalse();
    });

    test('images compare by byte content', () {
      final a = MKAnnotationIcon.image(Uint8List.fromList([1, 2]));
      final b = MKAnnotationIcon.image(Uint8List.fromList([1, 2]));
      final c = MKAnnotationIcon.image(Uint8List.fromList([9]));
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
      check(a == c).isFalse();
    });

    test('marker and image never compare equal', () {
      check(
        const MKAnnotationIcon.marker() == MKAnnotationIcon.image(Uint8List(0)),
      ).isFalse();
    });
  });
}
