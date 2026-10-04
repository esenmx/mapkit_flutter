// Value-type regressions: copyWith clearing nullable fields, longitude
// normalisation leaving in-range values untouched, and signed-zero equality.
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  const here = CLLocationCoordinate2D(latitude: 1, longitude: 2);

  group('copyWith clears nullable fields with an explicit null', () {
    test(
      'MKPointAnnotation.copyWith(clusteringIdentifier: null) un-clusters',
      () {
        const a = MKPointAnnotation(
          id: MKAnnotationId('a'),
          coordinate: here,
          title: 'Title',
          clusteringIdentifier: 'shops',
        );
        final b = a.copyWith(clusteringIdentifier: null, title: null);
        expect(
          b.clusteringIdentifier,
          isNull,
          reason: 'cannot leave a cluster',
        );
        expect(b.title, isNull, reason: 'cannot drop the callout title');
      },
    );

    test(
      'MKPolyline.copyWith(lineDashPattern: null) restores a solid stroke',
      () {
        const dashed = MKPolyline(
          id: MKPolylineId('p'),
          coordinates: [here, here],
          lineDashPattern: [6, 3],
        );
        expect(dashed.copyWith(lineDashPattern: null).lineDashPattern, isNull);
      },
    );
  });

  group('longitude normalisation keeps in-range values verbatim', () {
    test('an in-range longitude is stored verbatim', () {
      const c = CLLocationCoordinate2D(latitude: 0, longitude: 10.1);
      expect(c.longitude, 10.1);
    });

    test('control: the README longitude survives verbatim', () {
      const c = CLLocationCoordinate2D(
        latitude: 37.334922,
        longitude: -122.009033,
      );
      expect(c.longitude, -122.009033);
    });
  });

  test('control: -0.0 and 0.0 coordinates are equal with equal hashCodes', () {
    // Signed zero is the point of this control; `-0` would be the int 0.
    // ignore: prefer_int_literals
    const a = CLLocationCoordinate2D(latitude: -0.0, longitude: -0.0);
    const b = CLLocationCoordinate2D(latitude: 0, longitude: 0);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
