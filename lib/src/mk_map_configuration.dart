import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';
import 'package:mapkit_flutter/src/mk_point_of_interest_filter.dart';

/// The map's base style, mirroring `MKMapConfiguration` and assigned to
/// `MKMapView.preferredConfiguration`: [MKStandardMapConfiguration],
/// [MKHybridMapConfiguration], or [MKImageryMapConfiguration].
///
/// View-level switches (`showsCompass`, `isZoomEnabled`, tracking…) live as
/// direct `MKMapView` widget parameters, exactly as they are properties of
/// `MKMapView` rather than of the configuration in MapKit.
/// See: https://developer.apple.com/documentation/mapkit/mkmapconfiguration
@immutable
sealed class MKMapConfiguration {
  const MKMapConfiguration({required this.elevationStyle});

  /// Flat versus realistic 3-D terrain (`MKMapConfiguration.elevationStyle`).
  final MKMapElevationStyle elevationStyle;
}

/// Roads-and-labels base map (`MKStandardMapConfiguration`).
/// See: https://developer.apple.com/documentation/mapkit/mkstandardmapconfiguration
final class MKStandardMapConfiguration extends MKMapConfiguration {
  /// Creates a new MKStandardMapConfiguration object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkstandardmapconfiguration
  const MKStandardMapConfiguration({
    super.elevationStyle = .flat,
    this.emphasisStyle = .standard,
    this.pointOfInterestFilter = .includingAll,
    this.showsTraffic = false,
  });

  /// Label and feature emphasis; `standard` maps to Apple's `.default`.
  final MKMapEmphasisStyle emphasisStyle;

  /// The pointOfInterestFilter property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkstandardmapconfiguration/pointofinterestfilter
  final MKPointOfInterestFilter pointOfInterestFilter;

  /// The showsTraffic property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkstandardmapconfiguration/showstraffic
  final bool showsTraffic;

  @override
  bool operator ==(Object other) =>
      other is MKStandardMapConfiguration &&
      other.elevationStyle == elevationStyle &&
      other.emphasisStyle == emphasisStyle &&
      other.pointOfInterestFilter == pointOfInterestFilter &&
      other.showsTraffic == showsTraffic;

  @override
  int get hashCode => Object.hash(
    elevationStyle,
    emphasisStyle,
    pointOfInterestFilter,
    showsTraffic,
  );

  @override
  String toString() =>
      'MKStandardMapConfiguration(elevationStyle: ${elevationStyle.name}, '
      'emphasisStyle: ${emphasisStyle.name}, showsTraffic: $showsTraffic)';
}

/// Satellite imagery with roads and labels overlaid
/// (`MKHybridMapConfiguration`).
/// See: https://developer.apple.com/documentation/mapkit/mkhybridmapconfiguration
final class MKHybridMapConfiguration extends MKMapConfiguration {
  /// Creates a new MKHybridMapConfiguration object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkhybridmapconfiguration
  const MKHybridMapConfiguration({
    super.elevationStyle = .flat,
    this.pointOfInterestFilter = .includingAll,
    this.showsTraffic = false,
  });

  /// The pointOfInterestFilter property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkhybridmapconfiguration/pointofinterestfilter
  final MKPointOfInterestFilter pointOfInterestFilter;

  /// The showsTraffic property.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkhybridmapconfiguration/showstraffic
  final bool showsTraffic;

  @override
  bool operator ==(Object other) =>
      other is MKHybridMapConfiguration &&
      other.elevationStyle == elevationStyle &&
      other.pointOfInterestFilter == pointOfInterestFilter &&
      other.showsTraffic == showsTraffic;

  @override
  int get hashCode =>
      Object.hash(elevationStyle, pointOfInterestFilter, showsTraffic);

  @override
  String toString() =>
      'MKHybridMapConfiguration(elevationStyle: ${elevationStyle.name}, '
      'showsTraffic: $showsTraffic)';
}

/// Satellite imagery with no labels (`MKImageryMapConfiguration`).
/// See: https://developer.apple.com/documentation/mapkit/mkimagerymapconfiguration
final class MKImageryMapConfiguration extends MKMapConfiguration {
  /// Creates a new MKImageryMapConfiguration object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit/mkimagerymapconfiguration
  const MKImageryMapConfiguration({super.elevationStyle = .flat});

  @override
  bool operator ==(Object other) =>
      other is MKImageryMapConfiguration &&
      other.elevationStyle == elevationStyle;

  @override
  int get hashCode => elevationStyle.hashCode;

  @override
  String toString() =>
      'MKImageryMapConfiguration(elevationStyle: ${elevationStyle.name})';
}
