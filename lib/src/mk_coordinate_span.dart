import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// The width and height of a map region in degrees, mirroring
/// `MKCoordinateSpan(latitudeDelta:longitudeDelta:)`.
/// See: https://developer.apple.com/documentation/mapkit/mkcoordinatespan
@immutable
final class MKCoordinateSpan {
  const MKCoordinateSpan({
    required this.latitudeDelta,
    required this.longitudeDelta,
  }) : assert(latitudeDelta >= 0, 'latitudeDelta must be >= 0'),
       assert(longitudeDelta >= 0, 'longitudeDelta must be >= 0');

  @internal
  factory MKCoordinateSpan.fromPlatform(PlatformCoordinateSpan p) =>
      MKCoordinateSpan(
        latitudeDelta: p.latitudeDelta,
        longitudeDelta: p.longitudeDelta,
      );

  final double latitudeDelta;
  final double longitudeDelta;

  @internal
  PlatformCoordinateSpan toPlatform() => PlatformCoordinateSpan(
    latitudeDelta: latitudeDelta,
    longitudeDelta: longitudeDelta,
  );

  @override
  bool operator ==(Object other) =>
      other is MKCoordinateSpan &&
      other.latitudeDelta == latitudeDelta &&
      other.longitudeDelta == longitudeDelta;

  @override
  int get hashCode => Object.hash(latitudeDelta, longitudeDelta);

  @override
  String toString() => 'MKCoordinateSpan($latitudeDelta, $longitudeDelta)';
}
