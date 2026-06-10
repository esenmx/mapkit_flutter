import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_coordinate_span.dart';
import 'package:meta/meta.dart';

/// A rectangular geographic region as a [center] plus a [span], mirroring
/// `MKCoordinateRegion(center:span:)`.
/// See: https://developer.apple.com/documentation/mapkit/mkcoordinateregion
@immutable
final class MKCoordinateRegion {
  const MKCoordinateRegion({required this.center, required this.span});

  @internal
  factory MKCoordinateRegion.fromPlatform(PlatformCoordinateRegion p) =>
      MKCoordinateRegion(
        center: .fromPlatform(p.center),
        span: .fromPlatform(p.span),
      );

  final CLLocationCoordinate2D center;
  final MKCoordinateSpan span;

  /// Smallest region that contains all given [coordinates].
  /// Returns null when [coordinates] is empty.
  ///
  /// Spans are computed on the plain degree axes — a coordinate set that
  /// straddles the antimeridian produces the wide (eastward) region.
  static MKCoordinateRegion? containing(
    Iterable<CLLocationCoordinate2D> coordinates,
  ) {
    if (coordinates.isEmpty) return null;
    var minLat = 90.0;
    var maxLat = -90.0;
    var minLng = 180.0;
    var maxLng = -180.0;
    for (final c in coordinates) {
      if (c.latitude < minLat) minLat = c.latitude;
      if (c.latitude > maxLat) maxLat = c.latitude;
      if (c.longitude < minLng) minLng = c.longitude;
      if (c.longitude > maxLng) maxLng = c.longitude;
    }
    return MKCoordinateRegion(
      center: CLLocationCoordinate2D(
        latitude: (minLat + maxLat) / 2,
        longitude: (minLng + maxLng) / 2,
      ),
      span: MKCoordinateSpan(
        latitudeDelta: maxLat - minLat,
        longitudeDelta: maxLng - minLng,
      ),
    );
  }

  /// Whether [coordinate] lies inside this region. Longitude is compared as
  /// the shortest angular distance from [center], so regions spanning the
  /// antimeridian behave correctly.
  bool contains(CLLocationCoordinate2D coordinate) {
    final latOk =
        (coordinate.latitude - center.latitude).abs() <= span.latitudeDelta / 2;
    final lngDistance =
        (coordinate.longitude - center.longitude + 540.0) % 360.0 - 180.0;
    return latOk && lngDistance.abs() <= span.longitudeDelta / 2;
  }

  @internal
  PlatformCoordinateRegion toPlatform() => PlatformCoordinateRegion(
    center: center.toPlatform(),
    span: span.toPlatform(),
  );

  @override
  bool operator ==(Object other) =>
      other is MKCoordinateRegion &&
      other.center == center &&
      other.span == span;

  @override
  int get hashCode => Object.hash(center, span);

  @override
  String toString() => 'MKCoordinateRegion(center: $center, span: $span)';
}
