// Pigeon schema for the type-safe Dart <-> Swift boundary.
//
// Regenerate after editing:
//   dart run pigeon --input pigeons/messages.dart
//
// Generated files (`lib/src/messages.g.dart`, `ios/Classes/messages.g.swift`)
// are checked in and must not be hand-edited.
//
// Naming: every type here carries a `Platform` prefix — including enums that
// the public API re-exports via `typedef` (e.g. `MKUserTrackingMode =
// PlatformUserTrackingMode`). The prefix is load-bearing on the Swift side:
// this file generates into `messages.g.swift`, where an enum literally named
// `MKUserTrackingMode` or `CGLineCap` would shadow Apple's real types across
// the plugin module. Keep the prefix for any future addition.
//
// Error-code contract (host -> MapKitException at the controller):
//   snapshot-failed — `takeSnapshot` could not produce image data.
// Everything else degrades instead of throwing: unknown ids no-op,
// conversions return null pre-layout, `openLookAround` returns false.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'ios/Classes/messages.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'MapKitHostError'),
    dartPackageName: 'mapkit_flutter',
  ),
)
// ----------------------------- Enums -----------------------------
enum PlatformMapKind { standard, hybrid, imagery }

/// Label and feature emphasis on the standard map
/// (`MKStandardMapConfiguration.EmphasisStyle`).
///
/// `standard` maps to Apple's `.default` — `default` is a Dart reserved word.
/// See: https://developer.apple.com/documentation/mapkit/mkstandardmapconfiguration/emphasisstyle
enum PlatformMapEmphasisStyle { standard, muted }

/// Flat versus realistic 3-D terrain (`MKMapConfiguration.ElevationStyle`).
/// See: https://developer.apple.com/documentation/mapkit/mkmapconfiguration/elevationstyle
enum PlatformMapElevationStyle { flat, realistic }

/// How the map camera follows the user's location (`MKUserTrackingMode`).
/// See: https://developer.apple.com/documentation/mapkit/mkusertrackingmode
enum PlatformUserTrackingMode { none, follow, followWithHeading }

/// Stroke end-cap style for an `MKPolyline` (`CGLineCap`).
/// See: https://developer.apple.com/documentation/coregraphics/cglinecap
enum PlatformLineCap { butt, round, square }

/// Stroke join style between `MKPolyline` segments (`CGLineJoin`).
/// See: https://developer.apple.com/documentation/coregraphics/cglinejoin
enum PlatformLineJoin { miter, round, bevel }

enum PlatformPOIMode { none, all, including, excluding }

/// Vertical placement of an overlay relative to the base map's own labels and
/// roads (`MKOverlayLevel`).
/// See: https://developer.apple.com/documentation/mapkit/mkoverlaylevel
enum PlatformOverlayLevel {
  /// Drawn above roads but below map labels (POIs, place names). Default.
  aboveRoads,

  /// Drawn above everything, including labels.
  aboveLabels,
}

/// Mirrors `MKPointOfInterestCategory`.
/// See: https://developer.apple.com/documentation/mapkit/mkpointofinterestcategory
enum PlatformPointOfInterestCategory {
  airport,
  amusementPark,
  aquarium,
  atm,
  bakery,
  bank,
  beach,
  brewery,
  cafe,
  campground,
  carRental,
  evCharger,
  fireStation,
  fitnessCenter,
  foodMarket,
  gasStation,
  hospital,
  hotel,
  laundry,
  library,
  marina,
  movieTheater,
  museum,
  nationalPark,
  nightlife,
  park,
  parking,
  pharmacy,
  police,
  postOffice,
  publicTransport,
  restaurant,
  restroom,
  school,
  stadium,
  store,
  theater,
  university,
  winery,
  zoo,
}

/// Map features the user can select (`MKMapFeatureOptions`).
/// See: https://developer.apple.com/documentation/mapkit/mkmapfeatureoptions
enum PlatformMapFeatureOptions {
  pointsOfInterest,
  territories,
  physicalFeatures,
}

enum PlatformAnnotationIconType { marker, image }

// ----------------------------- Data classes -----------------------------

class PlatformCoordinate {
  PlatformCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class PlatformCoordinateSpan {
  PlatformCoordinateSpan({
    required this.latitudeDelta,
    required this.longitudeDelta,
  });

  final double latitudeDelta;
  final double longitudeDelta;
}

class PlatformCoordinateRegion {
  PlatformCoordinateRegion({required this.center, required this.span});

  final PlatformCoordinate center;
  final PlatformCoordinateSpan span;
}

/// Mirrors `MKMapCamera`: [distance] is `centerCoordinateDistance` in meters.
class PlatformMapCamera {
  PlatformMapCamera({
    required this.centerCoordinate,
    required this.distance,
    required this.heading,
    required this.pitch,
  });

  final PlatformCoordinate centerCoordinate;
  final double distance;
  final double heading;
  final double pitch;
}

class PlatformPoint {
  PlatformPoint({required this.x, required this.y});

  final double x;
  final double y;
}

/// Discriminated union of the `MKAnnotationIcon` variants. Only the fields
/// relevant to [type] are non-null.
class PlatformAnnotationIcon {
  PlatformAnnotationIcon({
    required this.type,
    this.markerTintArgb,
    this.glyphText,
    this.glyphSystemImage,
    this.glyphTintArgb,
    this.imageBytes,
  });

  final PlatformAnnotationIconType type;

  /// `MKMarkerAnnotationView.markerTintColor` (ARGB) for the `marker` variant.
  final int? markerTintArgb;

  /// `MKMarkerAnnotationView.glyphText` for the `marker` variant.
  final String? glyphText;

  /// SF Symbol name for `MKMarkerAnnotationView.glyphImage`.
  final String? glyphSystemImage;

  /// `MKMarkerAnnotationView.glyphTintColor` (ARGB).
  final int? glyphTintArgb;

  /// Raw PNG bytes for the `image` variant (`MKAnnotationView.image`).
  final Uint8List? imageBytes;
}

class PlatformAnnotation {
  PlatformAnnotation({
    required this.id,
    required this.coordinate,
    required this.icon,
    required this.calloutConsumesTapEvents,
    required this.alpha,
    required this.anchorPointX,
    required this.anchorPointY,
    required this.isDraggable,
    required this.isHidden,
    required this.zPriority,
    this.title,
    this.subtitle,
    this.clusteringIdentifier,
  });

  final String id;
  final PlatformCoordinate coordinate;
  final PlatformAnnotationIcon icon;
  final String? title;
  final String? subtitle;
  final bool calloutConsumesTapEvents;
  final double alpha;
  final double anchorPointX;
  final double anchorPointY;
  final bool isDraggable;
  final bool isHidden;
  final double zPriority;
  final String? clusteringIdentifier;
}

class PlatformPolyline {
  PlatformPolyline({
    required this.id,
    required this.coordinates,
    required this.strokeColorArgb,
    required this.lineWidth,
    required this.lineCap,
    required this.lineJoin,
    required this.isHidden,
    required this.consumeTapEvents,
    required this.isGeodesic,
    required this.level,
    required this.zIndex,
    this.lineDashPattern,
    this.gradientColorsArgb,
  });

  final String id;
  final List<PlatformCoordinate> coordinates;
  final int strokeColorArgb;
  final double lineWidth;
  final PlatformLineCap lineCap;
  final PlatformLineJoin lineJoin;
  final bool isHidden;
  final bool consumeTapEvents;
  final bool isGeodesic;
  final PlatformOverlayLevel level;
  final int zIndex;

  /// Alternating dash/gap lengths in points (`lineDashPattern`).
  final List<double>? lineDashPattern;

  /// When non-empty, renders with `MKGradientPolylineRenderer` spreading these
  /// ARGB colors evenly across the line.
  final List<int>? gradientColorsArgb;
}

class PlatformPolygon {
  PlatformPolygon({
    required this.id,
    required this.coordinates,
    required this.interiorPolygons,
    required this.fillColorArgb,
    required this.strokeColorArgb,
    required this.lineWidth,
    required this.zIndex,
    required this.isHidden,
    required this.consumeTapEvents,
    required this.level,
  });

  final String id;
  final List<PlatformCoordinate> coordinates;
  final List<List<PlatformCoordinate>> interiorPolygons;
  final int fillColorArgb;
  final int strokeColorArgb;
  final double lineWidth;
  final int zIndex;
  final bool isHidden;
  final bool consumeTapEvents;
  final PlatformOverlayLevel level;
}

class PlatformCircle {
  PlatformCircle({
    required this.id,
    required this.center,
    required this.radius,
    required this.fillColorArgb,
    required this.strokeColorArgb,
    required this.lineWidth,
    required this.zIndex,
    required this.isHidden,
    required this.consumeTapEvents,
    required this.level,
  });

  final String id;
  final PlatformCoordinate center;
  final double radius;
  final int fillColorArgb;
  final int strokeColorArgb;
  final double lineWidth;
  final int zIndex;
  final bool isHidden;
  final bool consumeTapEvents;
  final PlatformOverlayLevel level;
}

class PlatformTileOverlay {
  PlatformTileOverlay({
    required this.id,
    required this.urlTemplate,
    required this.minimumZ,
    required this.maximumZ,
    required this.tileSize,
    required this.canReplaceMapContent,
    required this.alpha,
    required this.level,
  });

  final String id;
  final String urlTemplate;
  final int minimumZ;
  final int maximumZ;
  final int tileSize;
  final bool canReplaceMapContent;
  final double alpha;
  final PlatformOverlayLevel level;
}

class PlatformPointOfInterestFilter {
  PlatformPointOfInterestFilter({required this.mode, required this.categories});

  final PlatformPOIMode mode;

  /// Only meaningful for [PlatformPOIMode.including] /
  /// [PlatformPOIMode.excluding].
  final List<PlatformPointOfInterestCategory> categories;
}

/// Mirrors `MKMapView.CameraZoomRange` — distances in meters.
class PlatformCameraZoomRange {
  PlatformCameraZoomRange({
    this.minCenterCoordinateDistance,
    this.maxCenterCoordinateDistance,
  });

  final double? minCenterCoordinateDistance;
  final double? maxCenterCoordinateDistance;
}

class PlatformMapConfiguration {
  PlatformMapConfiguration({
    required this.kind,
    required this.emphasisStyle,
    required this.elevationStyle,
    required this.showsTraffic,
    required this.showsCompass,
    required this.showsScale,
    required this.showsUserLocation,
    required this.showsUserTrackingButton,
    required this.userTrackingMode,
    required this.insetsLayoutMarginsFromSafeArea,
    required this.isRotateEnabled,
    required this.isScrollEnabled,
    required this.isZoomEnabled,
    required this.isPitchEnabled,
    required this.selectableMapFeatures,
    this.pointOfInterestFilter,
    this.cameraZoomRange,
    this.cameraBoundary,
  });

  final PlatformMapKind kind;
  final PlatformMapEmphasisStyle emphasisStyle;
  final PlatformMapElevationStyle elevationStyle;
  final bool showsTraffic;
  final bool showsCompass;
  final bool showsScale;
  final bool showsUserLocation;
  final bool showsUserTrackingButton;
  final PlatformUserTrackingMode userTrackingMode;
  final bool insetsLayoutMarginsFromSafeArea;
  final bool isRotateEnabled;
  final bool isScrollEnabled;
  final bool isZoomEnabled;
  final bool isPitchEnabled;
  final List<PlatformMapFeatureOptions> selectableMapFeatures;
  final PlatformPointOfInterestFilter? pointOfInterestFilter;
  final PlatformCameraZoomRange? cameraZoomRange;
  final PlatformCoordinateRegion? cameraBoundary;
}

/// Mirrors `MKMapSnapshotter.Options` plus plugin-drawn annotation/overlay
/// toggles.
class PlatformSnapshotOptions {
  PlatformSnapshotOptions({
    required this.showsBuildings,
    required this.showsPointsOfInterest,
    required this.showsAnnotations,
    required this.showsOverlays,
  });

  final bool showsBuildings;
  final bool showsPointsOfInterest;
  final bool showsAnnotations;
  final bool showsOverlays;
}

class PlatformMapViewCreationParams {
  PlatformMapViewCreationParams({
    required this.initialCamera,
    required this.configuration,
    required this.annotations,
    required this.polylines,
    required this.polygons,
    required this.circles,
  });

  final PlatformMapCamera initialCamera;
  final PlatformMapConfiguration configuration;
  final List<PlatformAnnotation> annotations;
  final List<PlatformPolyline> polylines;
  final List<PlatformPolygon> polygons;
  final List<PlatformCircle> circles;
}

// ----------------------------- APIs -----------------------------

/// Flutter -> host. One instance per platform view, keyed by the view id via
/// Pigeon's `messageChannelSuffix`.
@HostApi()
abstract class MapKitHostApi {
  /// Pushes the full initial state immediately after the platform view is
  /// created.
  void initialize(PlatformMapViewCreationParams params);

  // Pigeon API methods don't support named parameters, so the `animated`
  // bools below must stay positional.
  // ignore_for_file: avoid_positional_boolean_parameters

  /// `MKMapView.setCamera(_:animated:)`.
  void setCamera(PlatformMapCamera camera, bool animated);

  /// `MKMapView.setRegion(_:animated:)`.
  void setRegion(PlatformCoordinateRegion region, bool animated);

  /// `MKMapView.setCenter(_:animated:)`.
  void setCenter(PlatformCoordinate coordinate, bool animated);

  /// `MKMapView.camera`.
  PlatformMapCamera getCamera();

  /// `MKMapView.region`.
  PlatformCoordinateRegion getRegion();

  /// `MKMapView.convert(_:toPointTo:)`.
  PlatformPoint? convertToPoint(PlatformCoordinate coordinate);

  /// `MKMapView.convert(_:toCoordinateFrom:)`.
  PlatformCoordinate? convertToCoordinate(PlatformPoint point);

  void updateAnnotations(
    List<PlatformAnnotation> toAdd,
    List<PlatformAnnotation> toChange,
    List<String> idsToRemove,
  );
  void updatePolylines(
    List<PlatformPolyline> toAdd,
    List<PlatformPolyline> toChange,
    List<String> idsToRemove,
  );
  void updatePolygons(
    List<PlatformPolygon> toAdd,
    List<PlatformPolygon> toChange,
    List<String> idsToRemove,
  );
  void updateCircles(
    List<PlatformCircle> toAdd,
    List<PlatformCircle> toChange,
    List<String> idsToRemove,
  );

  void updateMapConfiguration(PlatformMapConfiguration configuration);

  void showCallout(String annotationId);
  void hideCallout(String annotationId);
  bool isCalloutShown(String annotationId);

  /// Throws: `snapshot-failed`.
  @async
  Uint8List takeSnapshot(PlatformSnapshotOptions options);

  @async
  bool openLookAround(PlatformCoordinate coordinate);

  void addTileOverlay(PlatformTileOverlay overlay);
  void removeTileOverlay(String tileOverlayId);
}

/// Host -> Flutter. One instance per platform view, keyed by view id.
@FlutterApi()
abstract class MapKitFlutterApi {
  void onCameraMoveStarted();
  void onCameraMove(PlatformMapCamera camera);
  void onCameraIdle();
  void onAnnotationTap(String annotationId);
  void onAnnotationDragStart(
    String annotationId,
    PlatformCoordinate coordinate,
  );
  void onAnnotationDrag(String annotationId, PlatformCoordinate coordinate);
  void onAnnotationDragEnd(String annotationId, PlatformCoordinate coordinate);
  void onCalloutTap(String annotationId);
  void onPolylineTap(String polylineId);
  void onPolygonTap(String polygonId);
  void onCircleTap(String circleId);
  void onMapTap(PlatformCoordinate coordinate);
  void onMapLongPress(PlatformCoordinate coordinate);

  /// `MKMapViewDelegate.mapViewDidFailLoadingMap(_:withError:)`.
  void onDidFailLoadingMap(String error);

  /// `MKMapViewDelegate.mapView(_:didFailToLocateUserWithError:)`.
  void onDidFailToLocateUser(String error);
}
