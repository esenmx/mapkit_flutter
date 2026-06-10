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
final class MKCameraZoomRange {
  const MKCameraZoomRange({
    this.minCenterCoordinateDistance,
    this.maxCenterCoordinateDistance,
  }) : assert(
         minCenterCoordinateDistance == null ||
             maxCenterCoordinateDistance == null ||
             minCenterCoordinateDistance <= maxCenterCoordinateDistance,
         'minCenterCoordinateDistance must be <= maxCenterCoordinateDistance',
       );

  final double? minCenterCoordinateDistance;
  final double? maxCenterCoordinateDistance;

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
