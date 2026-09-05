import 'package:flutter/foundation.dart';

/// Phantom-typed map-content identifier: [T] exists only to keep id kinds
/// apart at compile time — an `MKAnnotationId` never passes as an
/// `MKPolylineId`. Use the per-type typedefs, not `MapItemId` directly.
@immutable
final class const MapItemId<T>(
  /// The value property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  final String value,
) {
  /// Creates a new MapItemId object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapItemId<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MapItemId<$T>($value)';
}
