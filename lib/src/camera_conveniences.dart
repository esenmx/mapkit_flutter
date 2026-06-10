import 'dart:math' show pow;
import 'dart:ui' show Offset;

import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/mk_coordinate_region.dart';
import 'package:mapkit_flutter/src/mk_map_camera.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';

/// google_maps_flutter-dialect camera helpers layered over the canonical
/// MapKit surface. Every method composes [MKMapViewController.camera] with
/// `setCamera` / `setRegion` / `setCenter` — no extra platform calls exist
/// behind them.
///
/// Each call performs a read-then-write round trip, so during an active
/// user gesture the result may lag the live camera.
extension CameraConveniences on MKMapViewController {
  /// Approximate Web-Mercator zoom level of the current camera.
  ///
  /// google_maps_flutter dialect; canonical: `(await camera).zoomLevel`.
  Future<double> getZoomLevel() async => (await camera).zoomLevel;

  /// Move to an absolute zoom level, preserving center, heading, and pitch.
  ///
  /// google_maps_flutter dialect; canonical: `setCamera` with
  /// `MKMapCamera.withZoomLevel`.
  Future<void> zoomTo(double zoomLevel, {bool animated = true}) async {
    final current = await camera;
    await setCamera(
      MKMapCamera.withZoomLevel(
        centerCoordinate: current.centerCoordinate,
        zoomLevel: zoomLevel,
        heading: current.heading,
        pitch: current.pitch,
      ),
      animated: animated,
    );
  }

  /// Zoom by [amount] levels (positive zooms in), preserving center,
  /// heading, and pitch.
  ///
  /// google_maps_flutter dialect; canonical: `setCamera` with a scaled
  /// `MKMapCamera.distance`.
  Future<void> zoomBy(double amount, {bool animated = true}) async {
    final current = await camera;
    await setCamera(
      current.copyWith(distance: current.distance / pow(2.0, amount)),
      animated: animated,
    );
  }

  /// Zoom in one level. google_maps_flutter dialect.
  Future<void> zoomIn({bool animated = true}) => zoomBy(1, animated: animated);

  /// Zoom out one level. google_maps_flutter dialect.
  Future<void> zoomOut({bool animated = true}) =>
      zoomBy(-1, animated: animated);

  /// Pan the camera by a screen-pixel offset.
  ///
  /// google_maps_flutter dialect; canonical: the `convertToPoint` /
  /// `convertToCoordinate` pair plus `setCenter`. No-op while the view has
  /// no layout.
  Future<void> scrollBy(double dx, double dy, {bool animated = true}) async {
    final current = await camera;
    final centerPoint = await convertToPoint(current.centerCoordinate);
    if (centerPoint == null) return;
    final target = await convertToCoordinate(centerPoint + Offset(dx, dy));
    if (target == null) return;
    await setCenter(target, animated: animated);
  }

  /// Move the camera so all [coordinates] are visible.
  ///
  /// google_maps_flutter dialect (`CameraUpdate.newLatLngBounds`); canonical:
  /// `setRegion(MKCoordinateRegion.containing(coordinates))`. No-op when
  /// [coordinates] is empty.
  Future<void> fitCoordinates(
    Iterable<CLLocationCoordinate2D> coordinates, {
    bool animated = true,
  }) async {
    final region = MKCoordinateRegion.containing(coordinates);
    if (region == null) return;
    await setRegion(region, animated: animated);
  }
}
