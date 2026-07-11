import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:meta/meta.dart';

/// What a map snapshot includes, mirroring `MKMapSnapshotter.Options`
/// ([showsBuildings], [showsPointsOfInterest]) plus toggles for the
/// plugin-drawn [showsAnnotations] and [showsOverlays].
/// See: https://developer.apple.com/documentation/mapkit/mkmapsnapshotter/options
@immutable
final class MKMapSnapshotOptions {
  /// Creates a new MKMapSnapshotOptions object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkmapsnapshotoptions
  const MKMapSnapshotOptions({
    this.showsBuildings = true,
    this.showsPointsOfInterest = true,
    this.showsAnnotations = true,
    this.showsOverlays = true,
  });

  /// The showsBuildings property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkmapsnapshotoptions/showsbuildings
  final bool showsBuildings;

  /// The showsPointsOfInterest property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkmapsnapshotoptions/showspointsofinterest
  final bool showsPointsOfInterest;

  /// Whether the plugin draws the current annotations into the snapshot.
  final bool showsAnnotations;

  /// Whether the plugin draws the current overlays into the snapshot.
  final bool showsOverlays;

  @internal
  /// Creates a new Platform object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
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
