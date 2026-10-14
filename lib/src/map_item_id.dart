import 'package:flutter/foundation.dart';

/// Phantom-typed map-content identifier: [T] exists only to keep id kinds
/// apart at compile time — an `MKAnnotationId` never passes as an
/// `MKPolylineId`. Use the per-type typedefs, not `MapItemId` directly.
@immutable
final class const MapItemId<T>(
  /// Underlying string identifier.
  final String value,
) {
  /// Wraps [value] as a typed identifier.
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapItemId<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MapItemId<$T>($value)';
}
