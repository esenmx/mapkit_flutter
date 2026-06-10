import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  const osm = MKTileOverlay(
    id: MKTileOverlayId('osm'),
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  group('MKTileOverlay wire mapping', () {
    test('serializes MKTileOverlay vocabulary', () {
      final platform = const MKTileOverlay(
        id: MKTileOverlayId('osm'),
        urlTemplate: 'https://t/{z}/{x}/{y}.png',
        minimumZ: 3,
        maximumZ: 17,
        tileSize: 512,
        canReplaceMapContent: true,
        alpha: 0.5,
        level: .aboveLabels,
      ).toPlatform();

      check(platform.id).equals('osm');
      check(platform.urlTemplate).equals('https://t/{z}/{x}/{y}.png');
      check(platform.minimumZ).equals(3);
      check(platform.maximumZ).equals(17);
      check(platform.tileSize).equals(512);
      check(platform.canReplaceMapContent).isTrue();
      check(platform.alpha).equals(0.5);
      check(platform.level).equals(MKOverlayLevel.aboveLabels);
    });

    test('defaults mirror MKTileOverlay', () {
      final platform = osm.toPlatform();
      check(platform.minimumZ).equals(0);
      check(platform.maximumZ).equals(21);
      check(platform.tileSize).equals(256);
      check(platform.canReplaceMapContent).isFalse();
      check(platform.alpha).equals(1);
    });

    test('rejects an inverted z range', () {
      check(
        () => MKTileOverlay(
          id: const MKTileOverlayId('bad'),
          urlTemplate: 'https://t/{z}/{x}/{y}.png',
          minimumZ: 10,
          maximumZ: 3,
        ),
      ).throws<AssertionError>();
    });
  });

  group('equality', () {
    test('compares by value', () {
      check(osm).equals(
        const MKTileOverlay(
          id: MKTileOverlayId('osm'),
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
      );
      check(
        osm ==
            const MKTileOverlay(
              id: MKTileOverlayId('other'),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
      ).isFalse();
    });
  });
}
