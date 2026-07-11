import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// Shorthand alias for [CLLocationCoordinate2D]. Consumers who find the full
/// Apple symbol too long can use `Coordinate`; mixed-SDK files can `hide` it.
typedef Coordinate = CLLocationCoordinate2D;

/// A geographic latitude/longitude pair in degrees, mirroring Core Location's
/// `CLLocationCoordinate2D(latitude:longitude:)`.
///
/// Latitude is clamped to `[-90, 90]`; longitude is wrapped to `[-180, 180)`
/// (180° east normalizes to `-180`).
/// See: https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
@immutable
final class CLLocationCoordinate2D {
  /// Creates a new CLLocationCoordinate2D object.
  ///
  /// See: https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
  const CLLocationCoordinate2D({
    required double latitude,
    required double longitude,
  }) : latitude = (latitude < -90.0
           ? -90.0
           : (90.0 < latitude ? 90.0 : latitude)),
       longitude = (longitude + 180.0) % 360.0 - 180.0;

  @internal
  /// Creates a new CLLocationCoordinate2D object.
  ///
  /// See: https://developer.apple.com/documentation/corelocation/cllocationcoordinate2d
  factory CLLocationCoordinate2D.fromPlatform(PlatformCoordinate p) =>
      CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude);

  /// The latitude property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  final double latitude;

  /// The longitude property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  final double longitude;

  @internal
  /// Creates a new Platform object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  PlatformCoordinate toPlatform() =>
      PlatformCoordinate(latitude: latitude, longitude: longitude);

  @override
  bool operator ==(Object other) =>
      other is CLLocationCoordinate2D &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'CLLocationCoordinate2D($latitude, $longitude)';
}
