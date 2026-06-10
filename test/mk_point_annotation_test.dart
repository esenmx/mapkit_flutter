import 'dart:ui' show Color, Offset;

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import '_helpers/fixtures.dart';

void main() {
  group('MKPointAnnotation wire mapping', () {
    test('serializes MKAnnotationView vocabulary', () {
      final platform = const MKPointAnnotation(
        id: MKAnnotationId('a'),
        coordinate: applePark,
        icon: MKAnnotationIcon.marker(markerTintColor: Color(0xFF2266FF)),
        title: 'Apple Park',
        subtitle: 'Cupertino',
        alpha: 0.8,
        anchorPoint: Offset(0.5, 0.5),
        isDraggable: true,
        zPriority: 750,
        clusteringIdentifier: 'offices',
      ).toPlatform();

      check(platform.id).equals('a');
      check(platform.coordinate.latitude).equals(applePark.latitude);
      check(platform.title).equals('Apple Park');
      check(platform.subtitle).equals('Cupertino');
      check(platform.alpha).equals(0.8);
      check(platform.anchorPointX).equals(0.5);
      check(platform.anchorPointY).equals(0.5);
      check(platform.isDraggable).isTrue();
      check(platform.isHidden).isFalse();
      check(platform.zPriority).equals(750);
      check(platform.clusteringIdentifier).equals('offices');
    });

    test('callout consumes taps only when onCalloutTap is set', () {
      check(annotation('a').toPlatform().calloutConsumesTapEvents).isFalse();
      check(
        MKPointAnnotation(
          id: const MKAnnotationId('a'),
          coordinate: applePark,
          onCalloutTap: () {},
        ).toPlatform().calloutConsumesTapEvents,
      ).isTrue();
    });

    test('defaults mirror MKAnnotationView', () {
      final platform = annotation('a').toPlatform();
      check(platform.alpha).equals(1);
      check(platform.anchorPointX).equals(0.5);
      check(platform.anchorPointY).equals(1);
      check(platform.zPriority).equals(500);
      check(platform.isDraggable).isFalse();
      check(platform.clusteringIdentifier).isNull();
    });
  });

  group('equality', () {
    test('ignores callbacks, compares declarative fields', () {
      final a = MKPointAnnotation(
        id: const MKAnnotationId('a'),
        coordinate: applePark,
        onTap: () {},
      );
      final b = MKPointAnnotation(
        id: const MKAnnotationId('a'),
        coordinate: applePark,
        onTap: () {},
      );
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('different coordinates compare unequal', () {
      check(
        annotation('a') == annotation('a', coordinate: infiniteLoop),
      ).isFalse();
    });
  });

  group('copyWith', () {
    test('replaces only the given fields and keeps the id', () {
      final moved = annotation(
        'a',
        title: 't',
      ).copyWith(coordinate: infiniteLoop, isDraggable: true);
      check(moved.id).equals(const MKAnnotationId('a'));
      check(moved.coordinate).equals(infiniteLoop);
      check(moved.isDraggable).isTrue();
      check(moved.title).equals('t');
    });
  });

  group('clustering', () {
    test('annotations sharing a clusteringIdentifier serialize it', () {
      final ids = [
        const MKPointAnnotation(
          id: MKAnnotationId('a'),
          coordinate: applePark,
          clusteringIdentifier: 'stores',
        ),
        const MKPointAnnotation(
          id: MKAnnotationId('b'),
          coordinate: infiniteLoop,
          clusteringIdentifier: 'stores',
        ),
      ].map((a) => a.toPlatform().clusteringIdentifier).toSet();
      check(ids).deepEquals({'stores'});
    });
  });
}
