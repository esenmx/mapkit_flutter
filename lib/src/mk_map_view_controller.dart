import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mapkit_flutter/src/_internal/map_object_updates.dart';
import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/exceptions.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_circle.dart';
import 'package:mapkit_flutter/src/mk_coordinate_region.dart';
import 'package:mapkit_flutter/src/mk_map_camera.dart';
import 'package:mapkit_flutter/src/mk_map_snapshot_options.dart';
import 'package:mapkit_flutter/src/mk_point_annotation.dart';
import 'package:mapkit_flutter/src/mk_polygon.dart';
import 'package:mapkit_flutter/src/mk_polyline.dart';
import 'package:mapkit_flutter/src/mk_tile_overlay.dart';

/// Callbacks the widget hands to the controller for routing platform events
/// back to the widget API.
@internal
abstract interface class MKMapViewEventSink {
  void onCameraMoveStarted();
  void onCameraMove(MKMapCamera camera);
  void onCameraIdle();
  void onAnnotationTap(MKAnnotationId id);
  void onAnnotationDragStart(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
  );
  void onAnnotationDrag(MKAnnotationId id, CLLocationCoordinate2D coordinate);
  void onAnnotationDragEnd(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
  );
  void onCalloutTap(MKAnnotationId id);
  void onPolylineTap(MKPolylineId id);
  void onPolygonTap(MKPolygonId id);
  void onCircleTap(MKCircleId id);
  void onMapTap(CLLocationCoordinate2D coordinate);
  void onMapLongPress(CLLocationCoordinate2D coordinate);
  void onDidFailLoadingMap(String error);
  void onDidFailToLocateUser(String error);
}

/// Controller for a single `MKMapView` platform view, mirroring the
/// imperative half of `MKMapView`: [camera] / [region] state plus
/// [setCamera], [setRegion], [setCenter], and coordinate conversion.
///
/// All platform calls run through a type-safe Pigeon channel and are
/// serialized onto an internal queue, so concurrent calls execute in source
/// order. Failures surface as [MapKitException]s.
final class MKMapViewController {
  /// Internal constructor used by the `MKMapView` state when the platform
  /// view finishes initialization.
  ///
  /// [hostApi] is injectable for tests; in production it defaults to a Pigeon
  /// host API bound to this view's id.
  @internal
  factory MKMapViewController.create({
    required int viewId,
    required MKMapViewEventSink sink,
    @visibleForTesting MapKitHostApi? hostApi,
  }) {
    final suffix = '$viewId';
    final host = hostApi ?? MapKitHostApi(messageChannelSuffix: suffix);
    return MKMapViewController._(host, sink, suffix);
  }

  MKMapViewController._(
    this._host,
    MKMapViewEventSink sink,
    this._channelSuffix,
  ) : _eventHandler = _MKMapViewFlutterApi(sink) {
    MapKitFlutterApi.setUp(_eventHandler, messageChannelSuffix: _channelSuffix);
  }

  final MapKitHostApi _host;
  final String _channelSuffix;
  final MapKitFlutterApi _eventHandler;
  bool _disposed = false;

  /// The host→Flutter event handler, exposed for unit tests to simulate
  /// inbound platform callbacks without a live channel.
  @visibleForTesting
  MapKitFlutterApi get eventHandler => _eventHandler;

  // Serial queue: each public mutation enqueues onto _tail so platform
  // messages always land in source order.
  Future<void> _tail = Future.value();

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      if (_disposed) {
        completer.completeError(const MapKitDisposedException());
        return;
      }
      try {
        completer.complete(await task());
      } on PlatformException catch (e, st) {
        completer.completeError(MapKitException.fromPlatform(e), st);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  // ------------------------- Public API -------------------------

  /// The current camera (`MKMapView.camera`).
  Future<MKMapCamera> get camera =>
      _enqueue(() async => .fromPlatform(await _host.getCamera()));

  /// The currently visible region (`MKMapView.region`).
  ///
  /// Returns a zero region while the view has no layout (before the first
  /// frame).
  Future<MKCoordinateRegion> get region =>
      _enqueue(() async => .fromPlatform(await _host.getRegion()));

  /// `MKMapView.setCamera(_:animated:)`.
  Future<void> setCamera(MKMapCamera camera, {bool animated = true}) =>
      _enqueue(() => _host.setCamera(camera.toPlatform(), animated));

  /// `MKMapView.setRegion(_:animated:)`.
  Future<void> setRegion(MKCoordinateRegion region, {bool animated = true}) =>
      _enqueue(() => _host.setRegion(region.toPlatform(), animated));

  /// `MKMapView.setCenter(_:animated:)` — pans without changing distance,
  /// heading, or pitch.
  Future<void> setCenter(
    CLLocationCoordinate2D coordinate, {
    bool animated = true,
  }) => _enqueue(() => _host.setCenter(coordinate.toPlatform(), animated));

  /// Screen point for a coordinate (`MKMapView.convert(_:toPointTo:)`).
  /// Returns null while the view has no layout.
  Future<Offset?> convertToPoint(CLLocationCoordinate2D coordinate) => _enqueue(
    () async => switch (await _host.convertToPoint(coordinate.toPlatform())) {
      null => null,
      final point => Offset(point.x, point.y),
    },
  );

  /// Coordinate under a screen point
  /// (`MKMapView.convert(_:toCoordinateFrom:)`). Returns null while the view
  /// has no layout.
  Future<CLLocationCoordinate2D?> convertToCoordinate(Offset point) => _enqueue(
    () async => switch (await _host.convertToCoordinate(
      PlatformPoint(x: point.dx, y: point.dy),
    )) {
      null => null,
      final coordinate => .fromPlatform(coordinate),
    },
  );

  /// Select the annotation, showing its callout bubble.
  ///
  /// An id that is not on the map is ignored, matching
  /// `MKMapView.selectAnnotation(_:animated:)` semantics for foreign
  /// annotations — so a call racing a rebuild that removed the annotation is
  /// harmless.
  Future<void> showCallout(MKAnnotationId id) =>
      _enqueue(() => _host.showCallout(id.value));

  /// Deselect the annotation, hiding its callout bubble.
  ///
  /// An id that is not on the map is ignored (see [showCallout]).
  Future<void> hideCallout(MKAnnotationId id) =>
      _enqueue(() => _host.hideCallout(id.value));

  /// Whether the annotation is selected (its callout is showing). Returns
  /// `false` for an id that is not on the map.
  Future<bool> isCalloutShown(MKAnnotationId id) =>
      _enqueue(() => _host.isCalloutShown(id.value));

  /// Render the current map to a PNG via `MKMapSnapshotter`.
  ///
  /// Throws a [MapKitPlatformException] with code `snapshot-failed` when the
  /// snapshotter fails (e.g. tile loading) or produces no image data.
  Future<Uint8List> takeSnapshot([
    MKMapSnapshotOptions options = const MKMapSnapshotOptions(),
  ]) => _enqueue(() => _host.takeSnapshot(options.toPlatform()));

  /// Open the iOS Look Around (street-view) experience for a coordinate.
  ///
  /// Returns `true` if a Look Around scene was available and presented,
  /// `false` when no scene exists for the coordinate, the scene request
  /// failed (e.g. offline), or the viewer could not be presented.
  Future<bool> openLookAround(CLLocationCoordinate2D coordinate) =>
      _enqueue(() => _host.openLookAround(coordinate.toPlatform()));

  /// Add a custom raster tile overlay backed by a URL template.
  ///
  /// The template uses `{x}`, `{y}`, `{z}` placeholders, e.g.
  /// `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
  Future<void> addTileOverlay(MKTileOverlay overlay) =>
      _enqueue(() => _host.addTileOverlay(overlay.toPlatform()));

  /// Remove a previously-added tile overlay. Idempotent — an id that is not
  /// on the map is ignored.
  Future<void> removeTileOverlay(MKTileOverlayId id) =>
      _enqueue(() => _host.removeTileOverlay(id.value));

  // ------------------------- Internal mutations -------------------------

  @internal
  Future<void> initialize({
    required MKMapCamera initialCamera,
    required PlatformMapConfiguration configuration,
    required Set<MKPointAnnotation> annotations,
    required Set<MKPolyline> polylines,
    required Set<MKPolygon> polygons,
    required Set<MKCircle> circles,
  }) => _enqueue(
    () => _host.initialize(
      PlatformMapViewCreationParams(
        initialCamera: initialCamera.toPlatform(),
        configuration: configuration,
        annotations: annotations.map((a) => a.toPlatform()).toList(),
        polylines: polylines.map((p) => p.toPlatform()).toList(),
        polygons: polygons.map((p) => p.toPlatform()).toList(),
        circles: circles.map((c) => c.toPlatform()).toList(),
      ),
    ),
  );

  @internal
  Future<void> updateMapConfiguration(PlatformMapConfiguration configuration) =>
      _enqueue(() => _host.updateMapConfiguration(configuration));

  @internal
  Future<void> updateAnnotations(MapObjectUpdates<MKPointAnnotation> updates) =>
      _enqueue(
        () => _host.updateAnnotations(
          updates.toAdd.map((a) => a.toPlatform()).toList(),
          updates.toChange.map((a) => a.toPlatform()).toList(),
          updates.idsToRemove.toList(),
        ),
      );

  @internal
  Future<void> updatePolylines(MapObjectUpdates<MKPolyline> updates) =>
      _enqueue(
        () => _host.updatePolylines(
          updates.toAdd.map((p) => p.toPlatform()).toList(),
          updates.toChange.map((p) => p.toPlatform()).toList(),
          updates.idsToRemove.toList(),
        ),
      );

  @internal
  Future<void> updatePolygons(MapObjectUpdates<MKPolygon> updates) => _enqueue(
    () => _host.updatePolygons(
      updates.toAdd.map((p) => p.toPlatform()).toList(),
      updates.toChange.map((p) => p.toPlatform()).toList(),
      updates.idsToRemove.toList(),
    ),
  );

  @internal
  Future<void> updateCircles(MapObjectUpdates<MKCircle> updates) => _enqueue(
    () => _host.updateCircles(
      updates.toAdd.map((c) => c.toPlatform()).toList(),
      updates.toChange.map((c) => c.toPlatform()).toList(),
      updates.idsToRemove.toList(),
    ),
  );

  /// Release platform resources. Called automatically when the owning
  /// `MKMapView` widget unmounts.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    MapKitFlutterApi.setUp(null, messageChannelSuffix: _channelSuffix);
  }
}

/// Adapts the generated [MapKitFlutterApi] onto the widget's
/// [MKMapViewEventSink], converting `Platform*` payloads back to the public
/// model types.
final class _MKMapViewFlutterApi implements MapKitFlutterApi {
  _MKMapViewFlutterApi(this._sink);

  final MKMapViewEventSink _sink;

  @override
  void onCameraMoveStarted() => _sink.onCameraMoveStarted();

  @override
  void onCameraMove(PlatformMapCamera camera) =>
      _sink.onCameraMove(.fromPlatform(camera));

  @override
  void onCameraIdle() => _sink.onCameraIdle();

  @override
  void onAnnotationTap(String annotationId) =>
      _sink.onAnnotationTap(MKAnnotationId(annotationId));

  @override
  void onAnnotationDragStart(
    String annotationId,
    PlatformCoordinate coordinate,
  ) => _sink.onAnnotationDragStart(
    MKAnnotationId(annotationId),
    .fromPlatform(coordinate),
  );

  @override
  void onAnnotationDrag(String annotationId, PlatformCoordinate coordinate) =>
      _sink.onAnnotationDrag(
        MKAnnotationId(annotationId),
        .fromPlatform(coordinate),
      );

  @override
  void onAnnotationDragEnd(
    String annotationId,
    PlatformCoordinate coordinate,
  ) => _sink.onAnnotationDragEnd(
    MKAnnotationId(annotationId),
    .fromPlatform(coordinate),
  );

  @override
  void onCalloutTap(String annotationId) =>
      _sink.onCalloutTap(MKAnnotationId(annotationId));

  @override
  void onPolylineTap(String polylineId) =>
      _sink.onPolylineTap(MKPolylineId(polylineId));

  @override
  void onPolygonTap(String polygonId) =>
      _sink.onPolygonTap(MKPolygonId(polygonId));

  @override
  void onCircleTap(String circleId) => _sink.onCircleTap(MKCircleId(circleId));

  @override
  void onMapTap(PlatformCoordinate coordinate) =>
      _sink.onMapTap(.fromPlatform(coordinate));

  @override
  void onMapLongPress(PlatformCoordinate coordinate) =>
      _sink.onMapLongPress(.fromPlatform(coordinate));

  @override
  void onDidFailLoadingMap(String error) => _sink.onDidFailLoadingMap(error);

  @override
  void onDidFailToLocateUser(String error) =>
      _sink.onDidFailToLocateUser(error);
}
