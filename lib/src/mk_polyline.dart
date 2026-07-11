import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/map_item_id.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';

/// Type definition for MKPolylineId.
///
/// See: https://developer.apple.com/documentation/mapkit/mkpolylineid
typedef MKPolylineId = MapItemId<MKPolyline>;

/// A connected sequence of line segments through geographical [coordinates],
/// mirroring `MKPolyline` with its `MKPolylineRenderer` stroke properties
/// merged in ([strokeColor], [lineWidth], [lineCap], [lineJoin],
/// [lineDashPattern]).
///
/// [MKPolyline.geodesic] follows the shortest path over the globe
/// (`MKGeodesicPolyline`); a non-empty [gradientColors] renders with
/// `MKGradientPolylineRenderer`.
/// See: https://developer.apple.com/documentation/mapkit/mkpolyline
@immutable
final class MKPolyline {
  /// Straight-segment polyline (`MKPolyline`).
  const MKPolyline({
    required this.id,
    required this.coordinates,
    this.strokeColor = const Color(0xFF000000),
    this.lineWidth = 10,
    this.lineCap = .round,
    this.lineJoin = .round,
    this.lineDashPattern,
    this.gradientColors = const [],
    this.isHidden = false,
    this.zIndex = 0,
    this.consumeTapEvents = false,
    this.level = .aboveRoads,
    this.onTap,
  }) : isGeodesic = false;

  /// Polyline whose segments follow the shortest path over the globe,
  /// mirroring `MKGeodesicPolyline`.
  /// See: https://developer.apple.com/documentation/mapkit/mkgeodesicpolyline
  const MKPolyline.geodesic({
    required this.id,
    required this.coordinates,
    this.strokeColor = const Color(0xFF000000),
    this.lineWidth = 10,
    this.lineCap = .round,
    this.lineJoin = .round,
    this.lineDashPattern,
    this.gradientColors = const [],
    this.isHidden = false,
    this.zIndex = 0,
    this.consumeTapEvents = false,
    this.level = .aboveRoads,
    this.onTap,
  }) : isGeodesic = true;

  /// The id property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkpolyline/id
  final MKPolylineId id;

  /// The coordinates property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkpolyline/coordinates
  final List<CLLocationCoordinate2D> coordinates;

  /// Whether segments follow great-circle paths (`MKGeodesicPolyline`).
  final bool isGeodesic;

  /// Stroke color (`MKPolylineRenderer.strokeColor`). Ignored when
  /// [gradientColors] is non-empty.
  final Color strokeColor;

  /// Stroke width in points (`lineWidth`).
  final double lineWidth;

  /// Stroke end-cap style. MapKit's path renderer defaults to round caps and
  /// joins, mirrored here.
  final CGLineCap lineCap;

  /// The lineJoin property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkpolyline/linejoin
  final CGLineJoin lineJoin;

  /// Alternating dash/gap lengths in points (`lineDashPattern`), e.g.
  /// `[6, 3]`. `null` strokes solid. Dotted: `[0, lineWidth * 1.5]` with
  /// [CGLineCap.round].
  final List<double>? lineDashPattern;

  /// When non-empty, the line renders with a smooth gradient spreading these
  /// colors evenly from start to end (`MKGradientPolylineRenderer`), ignoring
  /// [strokeColor]. Requires at least two colors.
  final List<Color> gradientColors;

  /// The isHidden property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkpolyline/ishidden
  final bool isHidden;

  /// Flutter-side insertion-order hint between overlays. MapKit has no
  /// overlay z-index; ties resolve by insertion.
  final int zIndex;

  /// The consumeTapEvents property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkpolyline/consumetapevents
  final bool consumeTapEvents;

  /// Vertical placement relative to the base map's labels/roads.
  final MKOverlayLevel level;

  /// The onTap property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkpolyline/ontap
  final VoidCallback? onTap;

  /// Creates a new With object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  MKPolyline copyWith({
    List<CLLocationCoordinate2D>? coordinates,
    Color? strokeColor,
    double? lineWidth,
    CGLineCap? lineCap,
    CGLineJoin? lineJoin,
    List<double>? lineDashPattern,
    List<Color>? gradientColors,
    bool? isHidden,
    int? zIndex,
    bool? consumeTapEvents,
    MKOverlayLevel? level,
    VoidCallback? onTap,
  }) => (isGeodesic ? MKPolyline.geodesic : MKPolyline.new)(
    id: id,
    coordinates: coordinates ?? this.coordinates,
    strokeColor: strokeColor ?? this.strokeColor,
    lineWidth: lineWidth ?? this.lineWidth,
    lineCap: lineCap ?? this.lineCap,
    lineJoin: lineJoin ?? this.lineJoin,
    lineDashPattern: lineDashPattern ?? this.lineDashPattern,
    gradientColors: gradientColors ?? this.gradientColors,
    isHidden: isHidden ?? this.isHidden,
    zIndex: zIndex ?? this.zIndex,
    consumeTapEvents: consumeTapEvents ?? this.consumeTapEvents,
    level: level ?? this.level,
    onTap: onTap ?? this.onTap,
  );

  @internal
  /// Creates a new Platform object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  PlatformPolyline toPlatform() => PlatformPolyline(
    id: id.value,
    coordinates: coordinates.map((c) => c.toPlatform()).toList(),
    strokeColorArgb: strokeColor.toARGB32(),
    lineWidth: lineWidth,
    lineCap: lineCap,
    lineJoin: lineJoin,
    isHidden: isHidden,
    consumeTapEvents: consumeTapEvents,
    isGeodesic: isGeodesic,
    level: level,
    zIndex: zIndex,
    lineDashPattern: lineDashPattern,
    gradientColorsArgb: gradientColors.isEmpty
        ? null
        : gradientColors.map((c) => c.toARGB32()).toList(),
  );

  @override
  bool operator ==(Object other) =>
      other is MKPolyline &&
      other.id == id &&
      listEquals(other.coordinates, coordinates) &&
      other.isGeodesic == isGeodesic &&
      other.strokeColor == strokeColor &&
      other.lineWidth == lineWidth &&
      other.lineCap == lineCap &&
      other.lineJoin == lineJoin &&
      listEquals(other.lineDashPattern, lineDashPattern) &&
      listEquals(other.gradientColors, gradientColors) &&
      other.isHidden == isHidden &&
      other.zIndex == zIndex &&
      other.consumeTapEvents == consumeTapEvents &&
      other.level == level;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(coordinates),
    isGeodesic,
    strokeColor,
    lineWidth,
    lineCap,
    lineJoin,
    Object.hashAll(lineDashPattern ?? const []),
    Object.hashAll(gradientColors),
    isHidden,
    zIndex,
    consumeTapEvents,
    level,
  );

  @override
  String toString() {
    final b = StringBuffer('MKPolyline(')
      ..write('id: ${id.value}, ')
      ..write('coordinates: ${coordinates.length}, ')
      ..write('lineWidth: $lineWidth, ')
      ..write('isGeodesic: $isGeodesic, ')
      ..write('isHidden: $isHidden, ')
      ..write('level: ${level.name}, ')
      ..write('onTap: ${onTap != null ? 'set' : 'null'}');
    return (b..write(')')).toString();
  }
}
