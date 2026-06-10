import 'package:mapkit_flutter/src/messages.g.dart';

PlatformCoordinate platformCoord(double latitude, double longitude) =>
    PlatformCoordinate(latitude: latitude, longitude: longitude);

PlatformCoordinateSpan platformSpan({
  double latitudeDelta = 0,
  double longitudeDelta = 0,
}) => PlatformCoordinateSpan(
  latitudeDelta: latitudeDelta,
  longitudeDelta: longitudeDelta,
);

PlatformCoordinateRegion platformRegion({
  double latitude = 0,
  double longitude = 0,
  double latitudeDelta = 0,
  double longitudeDelta = 0,
}) => PlatformCoordinateRegion(
  center: platformCoord(latitude, longitude),
  span: platformSpan(
    latitudeDelta: latitudeDelta,
    longitudeDelta: longitudeDelta,
  ),
);

PlatformMapCamera platformCamera({
  double latitude = 0,
  double longitude = 0,
  double distance = 1000,
  double heading = 0,
  double pitch = 0,
}) => PlatformMapCamera(
  centerCoordinate: platformCoord(latitude, longitude),
  distance: distance,
  heading: heading,
  pitch: pitch,
);

PlatformPoint platformPoint(double x, double y) => PlatformPoint(x: x, y: y);
