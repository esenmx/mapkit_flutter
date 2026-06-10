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
typedef MKUserTrackingMode = PlatformUserTrackingMode;

/// `MKPointOfInterestCategory` — categories for `MKPointOfInterestFilter`.
typedef MKPointOfInterestCategory = PlatformPointOfInterestCategory;

/// `MKMapFeatureOptions` — map features the user can select.
typedef MKMapFeatureOptions = PlatformMapFeatureOptions;

/// `MKOverlayLevel` — overlay placement relative to roads and labels.
typedef MKOverlayLevel = PlatformOverlayLevel;

/// `CGLineCap` — stroke end-cap style.
typedef CGLineCap = PlatformLineCap;

/// `CGLineJoin` — stroke join style.
typedef CGLineJoin = PlatformLineJoin;
