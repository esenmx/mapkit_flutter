import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/map_item_id.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';
import 'package:meta/meta.dart';

typedef MKTileOverlayId = MapItemId<MKTileOverlay>;

/// Raster tile overlay drawn over the base map, mirroring
/// `MKTileOverlay(urlTemplate:)` with its renderer [alpha] merged in.
///
/// The [urlTemplate] uses `{x}`, `{y}`, `{z}` placeholders matching the
/// standard slippy-map scheme.
/// See: https://developer.apple.com/documentation/mapkit/mktileoverlay
@immutable
final class MKTileOverlay {
  const MKTileOverlay({
    required this.id,
    required this.urlTemplate,
    this.minimumZ = 0,
    this.maximumZ = 21,
    this.tileSize = 256,
    this.canReplaceMapContent = false,
    this.alpha = 1.0,
    this.level = .aboveRoads,
  }) : assert(0.0 <= alpha && alpha <= 1.0, 'alpha must be in [0, 1]'),
       assert(minimumZ <= maximumZ, 'minimumZ must be <= maximumZ');

  final MKTileOverlayId id;

  /// Slippy-map URL template, e.g.
  /// `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
  final String urlTemplate;

  /// Lowest tile zoom level the overlay serves (`MKTileOverlay.minimumZ`).
  final int minimumZ;

  /// Highest tile zoom level the overlay serves (`MKTileOverlay.maximumZ`).
  final int maximumZ;

  /// Tile size in points (`MKTileOverlay.tileSize`). Most providers serve
  /// 256-point tiles; Mapbox / Apple high-DPI sources use 512.
  final int tileSize;

  /// When `true`, the overlay replaces the base map underneath it
  /// (`MKTileOverlay.canReplaceMapContent`). Use for opaque world-coverage
  /// providers like a styled basemap; leave `false` for transparent
  /// supplemental layers.
  final bool canReplaceMapContent;

  /// Renderer opacity (`MKTileOverlayRenderer.alpha`). Default 1.0.
  final double alpha;

  /// Vertical placement relative to the base map's labels/roads.
  final MKOverlayLevel level;

  @internal
  PlatformTileOverlay toPlatform() => PlatformTileOverlay(
    id: id.value,
    urlTemplate: urlTemplate,
    minimumZ: minimumZ,
    maximumZ: maximumZ,
    tileSize: tileSize,
    canReplaceMapContent: canReplaceMapContent,
    alpha: alpha,
    level: level,
  );

  @override
  bool operator ==(Object other) =>
      other is MKTileOverlay &&
      other.id == id &&
      other.urlTemplate == urlTemplate &&
      other.minimumZ == minimumZ &&
      other.maximumZ == maximumZ &&
      other.tileSize == tileSize &&
      other.canReplaceMapContent == canReplaceMapContent &&
      other.alpha == alpha &&
      other.level == level;

  @override
  int get hashCode => Object.hash(
    id,
    urlTemplate,
    minimumZ,
    maximumZ,
    tileSize,
    canReplaceMapContent,
    alpha,
    level,
  );

  @override
  String toString() {
    final b = StringBuffer('MKTileOverlay(')
      ..write('id: ${id.value}, ')
      ..write('urlTemplate: $urlTemplate, ')
      ..write('z: $minimumZ-$maximumZ, ')
      ..write('alpha: $alpha, ')
      ..write('level: ${level.name}');
    return (b..write(')')).toString();
  }
}
