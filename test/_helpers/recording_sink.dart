import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';

/// Captures every callback the controller routes to its sink. One per
/// test — assert on `events` to verify dispatch.
final class RecordingSink implements MKMapViewEventSink {
  final List<(String, Object?)> events = [];

  @override
  void onCameraMoveStarted() => events.add(('cameraMoveStarted', null));

  @override
  void onCameraMove(MKMapCamera camera) => events.add(('cameraMove', camera));

  @override
  void onCameraIdle() => events.add(('cameraIdle', null));

  @override
  void onAnnotationTap(MKAnnotationId id) => events.add(('annotationTap', id));

  @override
  void onAnnotationDragStart(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
  ) => events.add(('annotationDragStart', (id, coordinate)));

  @override
  void onAnnotationDrag(MKAnnotationId id, CLLocationCoordinate2D coordinate) =>
      events.add(('annotationDrag', (id, coordinate)));

  @override
  void onAnnotationDragEnd(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
  ) => events.add(('annotationDragEnd', (id, coordinate)));

  @override
  void onCalloutTap(MKAnnotationId id) => events.add(('calloutTap', id));

  @override
  void onPolylineTap(MKPolylineId id) => events.add(('polylineTap', id));

  @override
  void onPolygonTap(MKPolygonId id) => events.add(('polygonTap', id));

  @override
  void onCircleTap(MKCircleId id) => events.add(('circleTap', id));

  @override
  void onMapTap(CLLocationCoordinate2D coordinate) =>
      events.add(('mapTap', coordinate));

  @override
  void onMapLongPress(CLLocationCoordinate2D coordinate) =>
      events.add(('mapLongPress', coordinate));

  @override
  void onDidFailLoadingMap(String error) =>
      events.add(('didFailLoadingMap', error));

  @override
  void onDidFailToLocateUser(String error) =>
      events.add(('didFailToLocateUser', error));
}
