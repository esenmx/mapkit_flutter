import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// Limits how close and how far the camera can get, mirroring
/// `MKMapView.CameraZoomRange` — both bounds are camera distances in meters
/// (`centerCoordinateDistance`), not tile zoom levels.
///
/// The default `MKCameraZoomRange()` leaves both ends unbounded.
/// See: https://developer.apple.com/documentation/mapkit/mkmapview/camerazoomrange
@immutable
final class const MKCameraZoomRange({
  /// Minimum camera center-coordinate distance in meters, or `null` if
  /// unbounded.
  final double? minCenterCoordinateDistance,

  /// Maximum camera center-coordinate distance in meters, or `null` if
  /// unbounded.
  final double? maxCenterCoordinateDistance,
}) {
  /// Creates a camera zoom range with optional minimum and maximum center
  /// distances in meters.
  this
    : assert(
        minCenterCoordinateDistance == null ||
            (minCenterCoordinateDistance >= 0 &&
                minCenterCoordinateDistance < double.infinity),
        'minCenterCoordinateDistance must be a finite value >= 0',
      ),
      assert(
        maxCenterCoordinateDistance == null ||
            (maxCenterCoordinateDistance >= 0 &&
                maxCenterCoordinateDistance < double.infinity),
        'maxCenterCoordinateDistance must be a finite value >= 0',
      ),
      assert(
        minCenterCoordinateDistance == null ||
            maxCenterCoordinateDistance == null ||
            minCenterCoordinateDistance <= maxCenterCoordinateDistance,
        'minCenterCoordinateDistance must be <= maxCenterCoordinateDistance',
      );

  /// Converts this zoom range to its Pigeon wire representation.
  @internal
  PlatformCameraZoomRange toPlatform() => PlatformCameraZoomRange(
    minCenterCoordinateDistance: minCenterCoordinateDistance,
    maxCenterCoordinateDistance: maxCenterCoordinateDistance,
  );

  @override
  bool operator ==(Object other) =>
      other is MKCameraZoomRange &&
      other.minCenterCoordinateDistance == minCenterCoordinateDistance &&
      other.maxCenterCoordinateDistance == maxCenterCoordinateDistance;

  @override
  int get hashCode =>
      Object.hash(minCenterCoordinateDistance, maxCenterCoordinateDistance);

  @override
  String toString() =>
      'MKCameraZoomRange(min: $minCenterCoordinateDistance, '
      'max: $maxCenterCoordinateDistance)';
}
