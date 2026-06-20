/// MapKit for Flutter.
///
/// iOS and macOS plugin that wraps `MKMapView` as a Flutter platform view.
/// Every public type carries Apple's exact MapKit symbol name (`MKMapCamera`,
/// `MKPolyline`, `CLLocationCoordinate2D`…), so the API reads like MapKit and
/// never collides with google_maps_flutter / mapbox_maps_flutter in
/// mixed-platform code.
library;

export 'src/camera_conveniences.dart';
export 'src/cl_location_coordinate_2d.dart';
export 'src/exceptions.dart';
export 'src/map_item_id.dart';
export 'src/mk_annotation_icon.dart';
export 'src/mk_camera_zoom_range.dart';
export 'src/mk_circle.dart';
export 'src/mk_coordinate_region.dart';
export 'src/mk_coordinate_span.dart';
export 'src/mk_enums.dart';
export 'src/mk_map_camera.dart';
export 'src/mk_map_configuration.dart';
export 'src/mk_map_snapshot_options.dart';
export 'src/mk_map_view.dart';
export 'src/mk_map_view_controller.dart' hide MKMapViewEventSink;
export 'src/mk_point_annotation.dart';
export 'src/mk_point_of_interest_filter.dart';
export 'src/mk_polygon.dart';
export 'src/mk_polyline.dart';
export 'src/mk_tile_overlay.dart';
