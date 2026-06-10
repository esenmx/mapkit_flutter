import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/map_item_id.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';

typedef MKPolygonId = MapItemId<MKPolygon>;

/// A filled, closed shape defined by an outer ring of [coordinates], with
/// optional [interiorPolygons] cut out of it — mirroring
/// `MKPolygon(coordinates:interiorPolygons:)` with its `MKPolygonRenderer`
/// fill/stroke properties merged in.
/// See: https://developer.apple.com/documentation/mapkit/mkpolygon
@immutable
final class MKPolygon {
  const MKPolygon({
    required this.id,
    required this.coordinates,
    this.interiorPolygons = const [],
    this.fillColor = const Color(0x00000000),
    this.strokeColor = const Color(0xFF000000),
    this.lineWidth = 10,
    this.zIndex = 0,
    this.isHidden = false,
    this.consumeTapEvents = false,
    this.level = .aboveRoads,
    this.onTap,
  });

  final MKPolygonId id;
  final List<CLLocationCoordinate2D> coordinates;

  /// Rings cut out of the filled shape (`MKPolygon.interiorPolygons`).
  final List<List<CLLocationCoordinate2D>> interiorPolygons;

  final Color fillColor;
  final Color strokeColor;

  /// Stroke width in points (`lineWidth`).
  final double lineWidth;

  /// Flutter-side insertion-order hint between overlays. MapKit has no
  /// overlay z-index; ties resolve by insertion.
  final int zIndex;

  final bool isHidden;
  final bool consumeTapEvents;

  /// Vertical placement relative to the base map's labels/roads.
  final MKOverlayLevel level;

  final VoidCallback? onTap;

  MKPolygon copyWith({
    List<CLLocationCoordinate2D>? coordinates,
    List<List<CLLocationCoordinate2D>>? interiorPolygons,
    Color? fillColor,
    Color? strokeColor,
    double? lineWidth,
    int? zIndex,
    bool? isHidden,
    bool? consumeTapEvents,
    MKOverlayLevel? level,
    VoidCallback? onTap,
  }) => MKPolygon(
    id: id,
    coordinates: coordinates ?? this.coordinates,
    interiorPolygons: interiorPolygons ?? this.interiorPolygons,
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
  PlatformPolygon toPlatform() => PlatformPolygon(
    id: id.value,
    coordinates: coordinates.map((c) => c.toPlatform()).toList(),
    interiorPolygons: interiorPolygons
        .map((ring) => ring.map((c) => c.toPlatform()).toList())
        .toList(),
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
      other is MKPolygon &&
      other.id == id &&
      listEquals(other.coordinates, coordinates) &&
      _ringsEqual(other.interiorPolygons, interiorPolygons) &&
      other.fillColor == fillColor &&
      other.strokeColor == strokeColor &&
      other.lineWidth == lineWidth &&
      other.zIndex == zIndex &&
      other.isHidden == isHidden &&
      other.consumeTapEvents == consumeTapEvents &&
      other.level == level;

  static bool _ringsEqual(
    List<List<CLLocationCoordinate2D>> a,
    List<List<CLLocationCoordinate2D>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(coordinates),
    Object.hashAll(interiorPolygons.map(Object.hashAll)),
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
    final b = StringBuffer('MKPolygon(')
      ..write('id: ${id.value}, ')
      ..write('coordinates: ${coordinates.length}, ')
      ..write('interiorPolygons: ${interiorPolygons.length}, ')
      ..write('lineWidth: $lineWidth, ')
      ..write('isHidden: $isHidden, ')
      ..write('level: ${level.name}, ')
      ..write('onTap: ${onTap != null ? 'set' : 'null'}');
    return (b..write(')')).toString();
  }
}
