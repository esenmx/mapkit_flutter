import 'package:flutter/foundation.dart';

/// Phantom-typed map-content identifier: [T] exists only to keep id kinds
/// apart at compile time — an `MKAnnotationId` never passes as an
/// `MKPolylineId`. Use the per-type typedefs, not `MapItemId` directly.
@immutable
final class MapItemId<T> {
  const MapItemId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapItemId<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MapItemId<$T>($value)';
}
