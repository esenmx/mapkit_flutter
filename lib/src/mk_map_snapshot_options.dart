import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// What a map snapshot includes, mirroring `MKMapSnapshotter.Options`
/// ([showsBuildings], [showsPointsOfInterest]) plus toggles for the
/// plugin-drawn [showsAnnotations] and [showsOverlays].
/// See: https://developer.apple.com/documentation/mapkit/mkmapsnapshotter/options
@immutable
final class const MKMapSnapshotOptions({
  /// No effect: MapKit no longer supports it; buildings follow the map's
  /// configuration.
  final bool showsBuildings = true,

  /// Whether points of interest appear in the snapshot.
  final bool showsPointsOfInterest = true,

  /// Whether the plugin draws the current annotations into the snapshot.
  /// iOS only; macOS snapshots contain the base map.
  final bool showsAnnotations = true,

  /// Whether the plugin draws the current overlays into the snapshot.
  /// iOS only; macOS snapshots contain the base map.
  final bool showsOverlays = true,
}) {
  /// Creates options controlling what a map snapshot includes.
  this;

  /// Converts these snapshot options to their Pigeon wire representation.
  @internal
  PlatformSnapshotOptions toPlatform() => PlatformSnapshotOptions(
    showsBuildings: showsBuildings,
    showsPointsOfInterest: showsPointsOfInterest,
    showsAnnotations: showsAnnotations,
    showsOverlays: showsOverlays,
  );

  @override
  bool operator ==(Object other) =>
      other is MKMapSnapshotOptions &&
      other.showsBuildings == showsBuildings &&
      other.showsPointsOfInterest == showsPointsOfInterest &&
      other.showsAnnotations == showsAnnotations &&
      other.showsOverlays == showsOverlays;

  @override
  int get hashCode => Object.hash(
    showsBuildings,
    showsPointsOfInterest,
    showsAnnotations,
    showsOverlays,
  );

  @override
  String toString() =>
      'MKMapSnapshotOptions(showsBuildings: $showsBuildings, '
      'showsPointsOfInterest: $showsPointsOfInterest, '
      'showsAnnotations: $showsAnnotations, showsOverlays: $showsOverlays)';
}
