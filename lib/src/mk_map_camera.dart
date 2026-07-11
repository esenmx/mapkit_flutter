import 'dart:math' show log, pow;

import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// The map's point of view, mirroring `MKMapCamera`: the camera looks at
/// [centerCoordinate] from [distance] meters (`centerCoordinateDistance`),
/// rotated to the compass [heading] and tilted by [pitch] degrees.
/// See: https://developer.apple.com/documentation/mapkit/mkmapcamera
@immutable
final class MKMapCamera {
  /// Creates a new MKMapCamera object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkmapcamera
  const MKMapCamera({
    required this.centerCoordinate,
    required this.distance,
    this.heading = 0.0,
    this.pitch = 0.0,
  }) : assert(distance > 0, 'distance must be > 0 meters');

  @internal
  /// Creates a new MKMapCamera object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkmapcamera
  factory MKMapCamera.fromPlatform(PlatformMapCamera p) => MKMapCamera(
    centerCoordinate: .fromPlatform(p.centerCoordinate),
    distance: p.distance,
    heading: p.heading,
    pitch: p.pitch,
  );

  /// Camera at the Web-Mercator [zoomLevel] familiar from tile-based SDKs.
  ///
  /// The conversion `distance = 591657550.5 / 2^(zoomLevel - 1)` is the
  /// de-facto standard approximation — it ignores latitude and viewport size,
  /// so treat zoom levels as a convenience, not an exact MapKit concept.
  factory MKMapCamera.withZoomLevel({
    required CLLocationCoordinate2D centerCoordinate,
    required double zoomLevel,
    double heading = 0.0,
    double pitch = 0.0,
  }) => MKMapCamera(
    centerCoordinate: centerCoordinate,
    distance: _zoomBaseDistance / pow(2.0, zoomLevel - 1),
    heading: heading,
    pitch: pitch,
  );

  /// The centerCoordinate property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkmapcamera/centercoordinate
  final CLLocationCoordinate2D centerCoordinate;

  /// `MKMapCamera.centerCoordinateDistance` — meters between the camera and
  /// [centerCoordinate].
  final double distance;

  /// Compass heading in degrees (0 = north).
  final double heading;

  /// Tilt in degrees (0 = looking straight down).
  final double pitch;

  /// Approximate Web-Mercator zoom level for [distance] — the inverse of
  /// [MKMapCamera.withZoomLevel], with the same caveats.
  double get zoomLevel => _log2(_zoomBaseDistance / distance) + 1;

  static const double _zoomBaseDistance = 591657550.5;

  static double _log2(double x) => log(x) / 0.6931471805599453;

  /// Creates a new With object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  MKMapCamera copyWith({
    CLLocationCoordinate2D? centerCoordinate,
    double? distance,
    double? heading,
    double? pitch,
  }) => MKMapCamera(
    centerCoordinate: centerCoordinate ?? this.centerCoordinate,
    distance: distance ?? this.distance,
    heading: heading ?? this.heading,
    pitch: pitch ?? this.pitch,
  );

  @internal
  /// Creates a new Platform object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  PlatformMapCamera toPlatform() => PlatformMapCamera(
    centerCoordinate: centerCoordinate.toPlatform(),
    distance: distance,
    heading: heading,
    pitch: pitch,
  );

  @override
  bool operator ==(Object other) =>
      other is MKMapCamera &&
      other.centerCoordinate == centerCoordinate &&
      other.distance == distance &&
      other.heading == heading &&
      other.pitch == pitch;

  @override
  int get hashCode => Object.hash(centerCoordinate, distance, heading, pitch);

  @override
  String toString() =>
      'MKMapCamera(centerCoordinate: $centerCoordinate, distance: $distance, '
      'heading: $heading, pitch: $pitch)';
}
