import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// The width and height of a map region in degrees, mirroring
/// `MKCoordinateSpan(latitudeDelta:longitudeDelta:)`.
/// See: https://developer.apple.com/documentation/mapkit/mkcoordinatespan
@immutable
final class const MKCoordinateSpan({
  /// The latitudeDelta property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcoordinatespan/latitudedelta
  required final double latitudeDelta,

  /// The longitudeDelta property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcoordinatespan/longitudedelta
  required final double longitudeDelta,
}) {
  /// Creates a new MKCoordinateSpan object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcoordinatespan
  this
    : assert(latitudeDelta >= 0, 'latitudeDelta must be >= 0'),
      assert(longitudeDelta >= 0, 'longitudeDelta must be >= 0');

  @internal
  /// Creates a new MKCoordinateSpan object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcoordinatespan
  factory fromPlatform(PlatformCoordinateSpan p) => MKCoordinateSpan(
    latitudeDelta: p.latitudeDelta,
    longitudeDelta: p.longitudeDelta,
  );

  @internal
  /// Creates a new Platform object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
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
