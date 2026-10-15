/// Public Apple-named aliases for the pigeon-generated wire enums.
///
/// The generated enums carry a `Platform` prefix because they also generate
/// into `messages.g.swift`, where Apple's real symbol names would shadow
/// MapKit/CoreGraphics types. These typedefs restore the exact Apple names on
/// the Dart side with zero case duplication.
library;

import 'package:mapkit_flutter/src/messages.g.dart';

/// `MKStandardMapConfiguration.EmphasisStyle`. `standard` maps to Apple's
/// `.default` (`default` is a Dart reserved word).
typedef MKMapEmphasisStyle = PlatformMapEmphasisStyle;

/// `MKMapConfiguration.ElevationStyle` — flat versus realistic 3-D terrain.
typedef MKMapElevationStyle = PlatformMapElevationStyle;

/// `MKUserTrackingMode` — how the camera follows the user's location.
/// `followWithHeading` is iOS only; `MKMapView` throws a
/// `MapKitUnsupportedPlatformException` for it on macOS.
typedef MKUserTrackingMode = PlatformUserTrackingMode;

/// `MKPointOfInterestCategory` — categories for `MKPointOfInterestFilter`.
///
/// Values documented as iOS 18 / macOS 15 need that OS: a filter naming one
/// on an older OS fails with a `MapKitPlatformException`
/// (`unavailable-poi-category`) instead of silently dropping it.
typedef MKPointOfInterestCategory = PlatformPointOfInterestCategory;

/// `MKMapFeatureOptions` — map features the user can select. iOS only.
typedef MKMapFeatureOptions = PlatformMapFeatureOptions;

/// MKMapFeatureAnnotation.FeatureType.
typedef MKMapFeatureType = PlatformMapFeatureType;

/// `MKOverlayLevel` — overlay placement relative to roads and labels.
typedef MKOverlayLevel = PlatformOverlayLevel;

/// `CGLineCap` — stroke end-cap style.
typedef CGLineCap = PlatformLineCap;

/// `CGLineJoin` — stroke join style.
typedef CGLineJoin = PlatformLineJoin;
