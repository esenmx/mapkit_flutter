import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapkit_flutter/src/_internal/map_object_updates.dart';
import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/exceptions.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_camera_zoom_range.dart';
import 'package:mapkit_flutter/src/mk_circle.dart';
import 'package:mapkit_flutter/src/mk_coordinate_region.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';
import 'package:mapkit_flutter/src/mk_map_camera.dart';
import 'package:mapkit_flutter/src/mk_map_configuration.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';
import 'package:mapkit_flutter/src/mk_point_annotation.dart';
import 'package:mapkit_flutter/src/mk_polygon.dart';
import 'package:mapkit_flutter/src/mk_polyline.dart';

/// Displays an Apple Maps `MKMapView` as a Flutter platform view.
///
/// Mirrors `MKMapView`'s own API shape: the base style is a sealed
/// [preferredConfiguration], while view-level switches ([showsUserLocation],
/// [isZoomEnabled], [cameraZoomRange]…) are direct parameters — exactly the
/// properties they are on `MKMapView`. Content is declarative: [annotations]
/// and overlay sets diff on rebuild.
///
/// iOS and macOS only. Building this widget on any other platform throws a
/// [MapKitUnsupportedPlatformException] rather than degrading silently.
/// See: https://developer.apple.com/documentation/mapkit/mkmapview
final class MKMapView extends StatefulWidget {
  const MKMapView({
    required this.initialCamera,
    super.key,
    this.preferredConfiguration = const MKStandardMapConfiguration(),
    this.isZoomEnabled = true,
    this.isScrollEnabled = true,
    this.isRotateEnabled = true,
    this.isPitchEnabled = true,
    this.showsUserLocation = false,
    this.showsUserTrackingButton = false,
    this.showsCompass = true,
    this.showsScale = false,
    this.userTrackingMode = .none,
    this.cameraZoomRange = const MKCameraZoomRange(),
    this.cameraBoundary,
    this.selectableMapFeatures = const {},
    this.insetsLayoutMarginsFromSafeArea = true,
    this.annotations = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.gestureRecognizers = const {},
    this.onMapCreated,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
    this.onDidFailLoadingMap,
    this.onDidFailToLocateUser,
    this.debugControllerFactory,
  });

  /// Where the camera starts (`MKMapCamera`).
  final MKMapCamera initialCamera;

  /// The map's base style (`MKMapView.preferredConfiguration`).
  final MKMapConfiguration preferredConfiguration;

  final bool isZoomEnabled;
  final bool isScrollEnabled;
  final bool isRotateEnabled;
  final bool isPitchEnabled;

  /// Requires `NSLocationWhenInUseUsageDescription` in `Info.plist`.
  final bool showsUserLocation;

  /// `MKMapView.showsUserTrackingButton` (iOS 17).
  final bool showsUserTrackingButton;

  final bool showsCompass;
  final bool showsScale;
  final MKUserTrackingMode userTrackingMode;

  /// Camera distance limits in meters (`MKMapView.cameraZoomRange`).
  final MKCameraZoomRange cameraZoomRange;

  /// Region the camera center is constrained to
  /// (`MKMapView.cameraBoundary`).
  final MKCoordinateRegion? cameraBoundary;

  /// Map features the user can tap to select
  /// (`MKMapView.selectableMapFeatures`).
  final Set<MKMapFeatureOptions> selectableMapFeatures;

  final bool insetsLayoutMarginsFromSafeArea;

  final Set<MKPointAnnotation> annotations;
  final Set<MKPolyline> polylines;
  final Set<MKPolygon> polygons;
  final Set<MKCircle> circles;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final void Function(MKMapViewController controller)? onMapCreated;
  final VoidCallback? onCameraMoveStarted;
  final void Function(MKMapCamera camera)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final void Function(CLLocationCoordinate2D coordinate)? onTap;
  final void Function(CLLocationCoordinate2D coordinate)? onLongPress;

  /// Map content failed to load, e.g. no network
  /// (`MKMapViewDelegate.mapViewDidFailLoadingMap(_:withError:)`).
  final ValueChanged<String>? onDidFailLoadingMap;

  /// The map could not determine the user's location — most commonly because
  /// location permission was denied — while [showsUserLocation] is enabled
  /// (`MKMapViewDelegate.mapView(_:didFailToLocateUserWithError:)`).
  final ValueChanged<String>? onDidFailToLocateUser;

  /// Replaces the platform view with an injected controller so widget tests
  /// can drive the full diff pipeline against a fake host API. When set,
  /// `build` renders a plain box instead of a `UiKitView`/`AppKitView` and
  /// skips the platform check.
  @visibleForTesting
  final MKMapViewController Function(MKMapViewEventSink sink)?
  debugControllerFactory;

  @override
  State<MKMapView> createState() => _MKMapViewState();
}

final class _MKMapViewState extends State<MKMapView>
    implements MKMapViewEventSink {
  MKMapViewController? _controller;

  late Map<MKAnnotationId, MKPointAnnotation> _annotations;
  late Map<MKPolylineId, MKPolyline> _polylines;
  late Map<MKPolygonId, MKPolygon> _polygons;
  late Map<MKCircleId, MKCircle> _circles;

  @override
  void initState() {
    super.initState();
    _annotations = {for (final a in widget.annotations) a.id: a};
    _polylines = {for (final p in widget.polylines) p.id: p};
    _polygons = {for (final p in widget.polygons) p.id: p};
    _circles = {for (final c in widget.circles) c.id: c};
    if (widget.debugControllerFactory case final factory?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _wireController(factory(this));
      });
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debugControllerFactory != null) return const SizedBox.expand();

    const viewType = 'dev.mapkit.flutter/map_view';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => UiKitView(
        viewType: viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
        creationParamsCodec: const StandardMessageCodec(),
      ),
      TargetPlatform.macOS => AppKitView(
        viewType: viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
        creationParamsCodec: const StandardMessageCodec(),
      ),
      _ => throw MapKitUnsupportedPlatformException(defaultTargetPlatform),
    };
  }

  void _onPlatformViewCreated(int id) =>
      _wireController(MKMapViewController.create(viewId: id, sink: this));

  /// Push the full initial state over the type-safe channel now that the
  /// platform view (and its host API handler) exists.
  void _wireController(MKMapViewController controller) {
    _controller = controller;
    unawaited(
      controller.initialize(
        initialCamera: widget.initialCamera,
        configuration: _platformConfiguration(),
        annotations: widget.annotations,
        polylines: widget.polylines,
        polygons: widget.polygons,
        circles: widget.circles,
      ),
    );
    widget.onMapCreated?.call(controller);
  }

  /// Flattens the sealed [MKMapConfiguration] plus the widget's view-level
  /// properties into the wire bundle.
  PlatformMapConfiguration _platformConfiguration() {
    final (
      PlatformMapKind kind,
      MKMapEmphasisStyle emphasisStyle,
      showsTraffic,
      pointOfInterestFilter,
    ) = switch (widget.preferredConfiguration) {
      MKStandardMapConfiguration(
        :final emphasisStyle,
        :final showsTraffic,
        :final pointOfInterestFilter,
      ) =>
        (.standard, emphasisStyle, showsTraffic, pointOfInterestFilter),
      MKHybridMapConfiguration(
        :final showsTraffic,
        :final pointOfInterestFilter,
      ) =>
        (.hybrid, .standard, showsTraffic, pointOfInterestFilter),
      MKImageryMapConfiguration() => (.imagery, .standard, false, null),
    };
    return PlatformMapConfiguration(
      kind: kind,
      emphasisStyle: emphasisStyle,
      elevationStyle: widget.preferredConfiguration.elevationStyle,
      showsTraffic: showsTraffic,
      showsCompass: widget.showsCompass,
      showsScale: widget.showsScale,
      showsUserLocation: widget.showsUserLocation,
      showsUserTrackingButton: widget.showsUserTrackingButton,
      userTrackingMode: widget.userTrackingMode,
      insetsLayoutMarginsFromSafeArea: widget.insetsLayoutMarginsFromSafeArea,
      isRotateEnabled: widget.isRotateEnabled,
      isScrollEnabled: widget.isScrollEnabled,
      isZoomEnabled: widget.isZoomEnabled,
      isPitchEnabled: widget.isPitchEnabled,
      selectableMapFeatures: widget.selectableMapFeatures.toList(),
      pointOfInterestFilter: pointOfInterestFilter?.toPlatform(),
      cameraZoomRange: widget.cameraZoomRange.toPlatform(),
      cameraBoundary: widget.cameraBoundary?.toPlatform(),
    );
  }

  bool _configurationChanged(MKMapView old) =>
      widget.preferredConfiguration != old.preferredConfiguration ||
      widget.isZoomEnabled != old.isZoomEnabled ||
      widget.isScrollEnabled != old.isScrollEnabled ||
      widget.isRotateEnabled != old.isRotateEnabled ||
      widget.isPitchEnabled != old.isPitchEnabled ||
      widget.showsUserLocation != old.showsUserLocation ||
      widget.showsUserTrackingButton != old.showsUserTrackingButton ||
      widget.showsCompass != old.showsCompass ||
      widget.showsScale != old.showsScale ||
      widget.userTrackingMode != old.userTrackingMode ||
      widget.cameraZoomRange != old.cameraZoomRange ||
      widget.cameraBoundary != old.cameraBoundary ||
      !setEquals(widget.selectableMapFeatures, old.selectableMapFeatures) ||
      widget.insetsLayoutMarginsFromSafeArea !=
          old.insetsLayoutMarginsFromSafeArea;

  @override
  void didUpdateWidget(covariant MKMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null) return;

    // Refresh the id→object dispatch tables on every rebuild, before the diff
    // gates below. The models' `==` excludes callbacks (so a closure swap
    // doesn't trigger a needless native recycle); a rebuild that changes only
    // an `onTap`/`onDrag*` closure is therefore `setEquals`-equal and skips the
    // native update — but these tables back inbound event dispatch and must
    // still pick up the fresh closures, or a tap fires stale captured state.
    _annotations = {for (final a in widget.annotations) a.id: a};
    _polylines = {for (final p in widget.polylines) p.id: p};
    _polygons = {for (final p in widget.polygons) p.id: p};
    _circles = {for (final o in widget.circles) o.id: o};

    if (_configurationChanged(oldWidget)) {
      unawaited(c.updateMapConfiguration(_platformConfiguration()));
    }
    if (!setEquals(widget.annotations, oldWidget.annotations)) {
      final updates = MapObjectUpdates.between(
        oldWidget.annotations,
        widget.annotations,
        idOf: (a) => a.id.value,
      );
      unawaited(c.updateAnnotations(updates));
    }
    if (!setEquals(widget.polylines, oldWidget.polylines)) {
      final updates = MapObjectUpdates.between(
        oldWidget.polylines,
        widget.polylines,
        idOf: (p) => p.id.value,
      );
      unawaited(c.updatePolylines(updates));
    }
    if (!setEquals(widget.polygons, oldWidget.polygons)) {
      final updates = MapObjectUpdates.between(
        oldWidget.polygons,
        widget.polygons,
        idOf: (p) => p.id.value,
      );
      unawaited(c.updatePolygons(updates));
    }
    if (!setEquals(widget.circles, oldWidget.circles)) {
      final updates = MapObjectUpdates.between(
        oldWidget.circles,
        widget.circles,
        idOf: (o) => o.id.value,
      );
      unawaited(c.updateCircles(updates));
    }
  }

  @override
  void onCameraMoveStarted() => widget.onCameraMoveStarted?.call();

  @override
  void onCameraMove(MKMapCamera camera) => widget.onCameraMove?.call(camera);

  @override
  void onCameraIdle() => widget.onCameraIdle?.call();

  @override
  void onAnnotationTap(MKAnnotationId id) => _annotations[id]?.onTap?.call();

  @override
  void onAnnotationDragStart(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
  ) => _annotations[id]?.onDragStart?.call(coordinate);

  @override
  void onAnnotationDrag(MKAnnotationId id, CLLocationCoordinate2D coordinate) =>
      _annotations[id]?.onDrag?.call(coordinate);

  @override
  void onAnnotationDragEnd(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
  ) => _annotations[id]?.onDragEnd?.call(coordinate);

  @override
  void onCalloutTap(MKAnnotationId id) =>
      _annotations[id]?.onCalloutTap?.call();

  @override
  void onPolylineTap(MKPolylineId id) => _polylines[id]?.onTap?.call();

  @override
  void onPolygonTap(MKPolygonId id) => _polygons[id]?.onTap?.call();

  @override
  void onCircleTap(MKCircleId id) => _circles[id]?.onTap?.call();

  @override
  void onMapTap(CLLocationCoordinate2D coordinate) =>
      widget.onTap?.call(coordinate);

  @override
  void onMapLongPress(CLLocationCoordinate2D coordinate) =>
      widget.onLongPress?.call(coordinate);

  @override
  void onDidFailLoadingMap(String error) =>
      widget.onDidFailLoadingMap?.call(error);

  @override
  void onDidFailToLocateUser(String error) =>
      widget.onDidFailToLocateUser?.call(error);
}
