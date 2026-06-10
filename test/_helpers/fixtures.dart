import 'package:mapkit_flutter/mapkit_flutter.dart';

/// Shared coordinates and one-liner model builders so tests don't restate
/// boilerplate.
const applePark = CLLocationCoordinate2D(
  latitude: 37.3349,
  longitude: -122.0090,
);

const infiniteLoop = CLLocationCoordinate2D(
  latitude: 37.3318,
  longitude: -122.0312,
);

const sampleCamera = MKMapCamera(centerCoordinate: applePark, distance: 1200);

const sampleRegion = MKCoordinateRegion(
  center: applePark,
  span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05),
);

MKPointAnnotation annotation(
  String id, {
  CLLocationCoordinate2D coordinate = applePark,
  String? title,
}) => MKPointAnnotation(
  id: MKAnnotationId(id),
  coordinate: coordinate,
  title: title,
);

MKPolyline polyline(String id, {List<CLLocationCoordinate2D>? coordinates}) =>
    MKPolyline(
      id: MKPolylineId(id),
      coordinates: coordinates ?? const [applePark, infiniteLoop],
    );

MKPolygon polygon(String id, {List<CLLocationCoordinate2D>? coordinates}) =>
    MKPolygon(
      id: MKPolygonId(id),
      coordinates:
          coordinates ??
          const [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0, longitude: 1),
            CLLocationCoordinate2D(latitude: 1, longitude: 1),
          ],
    );

MKCircle circle(String id, {double radius = 500}) =>
    MKCircle(id: MKCircleId(id), center: applePark, radius: radius);
