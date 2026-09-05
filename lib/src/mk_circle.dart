import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/map_item_id.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';

/// Type definition for MKCircleId.
///
/// See: https://developer.apple.com/documentation/mapkit/mkcircleid
typedef MKCircleId = MapItemId<MKCircle>;

/// A circle of a fixed [radius] in meters centered on a coordinate, mirroring
/// `MKCircle(center:radius:)` with its `MKCircleRenderer` fill/stroke
/// properties merged in.
/// See: https://developer.apple.com/documentation/mapkit/mkcircle
@immutable
final class const MKCircle({
  /// The id property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/id
  required final MKCircleId id,

  /// The center property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/center
  required final CLLocationCoordinate2D center,

  /// Radius in meters.
  required final double radius,

  /// The fillColor property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/fillcolor
  final Color fillColor = const Color(0x00000000),

  /// The strokeColor property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/strokecolor
  final Color strokeColor = const Color(0xFF000000),

  /// Stroke width in points (`lineWidth`).
  final double lineWidth = 10,

  /// Flutter-side insertion-order hint between overlays. MapKit has no
  /// overlay z-index; ties resolve by insertion.
  final int zIndex = 0,

  /// The isHidden property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/ishidden
  final bool isHidden = false,

  /// The consumeTapEvents property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/consumetapevents
  final bool consumeTapEvents = false,

  /// Vertical placement relative to the base map's labels/roads.
  final MKOverlayLevel level = .aboveRoads,

  /// The onTap property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle/ontap
  final VoidCallback? onTap,
}) {
  /// Creates a new MKCircle object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkcircle
  this : assert(radius >= 0, 'radius must be >= 0 meters');

  /// Creates a new With object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  MKCircle copyWith({
    CLLocationCoordinate2D? center,
    double? radius,
    Color? fillColor,
    Color? strokeColor,
    double? lineWidth,
    int? zIndex,
    bool? isHidden,
    bool? consumeTapEvents,
    MKOverlayLevel? level,
    VoidCallback? onTap,
  }) => MKCircle(
    id: id,
    center: center ?? this.center,
    radius: radius ?? this.radius,
    fillColor: fillColor ?? this.fillColor,
    strokeColor: strokeColor ?? this.strokeColor,
    lineWidth: lineWidth ?? this.lineWidth,
    zIndex: zIndex ?? this.zIndex,
    isHidden: isHidden ?? this.isHidden,
    consumeTapEvents: consumeTapEvents ?? this.consumeTapEvents,
    level: level ?? this.level,
    onTap: onTap ?? this.onTap,
  );

  @internal
  /// Creates a new Platform object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  PlatformCircle toPlatform() => PlatformCircle(
    id: id.value,
    center: center.toPlatform(),
    radius: radius,
    fillColorArgb: fillColor.toARGB32(),
    strokeColorArgb: strokeColor.toARGB32(),
    lineWidth: lineWidth,
    zIndex: zIndex,
    isHidden: isHidden,
    consumeTapEvents: consumeTapEvents,
    level: level,
  );

  @override
  bool operator ==(Object other) =>
      other is MKCircle &&
      other.id == id &&
      other.center == center &&
      other.radius == radius &&
      other.fillColor == fillColor &&
      other.strokeColor == strokeColor &&
      other.lineWidth == lineWidth &&
      other.zIndex == zIndex &&
      other.isHidden == isHidden &&
      other.consumeTapEvents == consumeTapEvents &&
      other.level == level;

  @override
  int get hashCode => Object.hash(
    id,
    center,
    radius,
    fillColor,
    strokeColor,
    lineWidth,
    zIndex,
    isHidden,
    consumeTapEvents,
    level,
  );

  @override
  String toString() {
    final b = StringBuffer('MKCircle(')
      ..write('id: ${id.value}, ')
      ..write('center: $center, ')
      ..write('radius: $radius, ')
      ..write('lineWidth: $lineWidth, ')
      ..write('isHidden: $isHidden, ')
      ..write('level: ${level.name}, ')
      ..write('onTap: ${onTap != null ? 'set' : 'null'}');
    return (b..write(')')).toString();
  }
}
