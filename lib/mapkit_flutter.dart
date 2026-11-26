/// MapKit for Flutter.
///
/// iOS and macOS plugin that wraps `MKMapView` as a Flutter platform view.
/// Every public type carries Apple's exact MapKit symbol name (`MKMapCamera`,
/// `MKPolyline`, `CLLocationCoordinate2D`…), so the API reads like MapKit and
/// never collides with google_maps_flutter / mapbox_maps_flutter in
/// mixed-platform code.
///
/// The enums are generated with a `Platform` prefix (`PlatformOverlayLevel`)
/// and exported under it so signatures and docs can name them; write the
/// Apple-named aliases (`MKOverlayLevel`, `CGLineCap`…).
library;

export 'src/camera_conveniences.dart';
export 'src/cl_location_coordinate_2d.dart' hide CLLocationCoordinate2DWire;
export 'src/exceptions.dart';
export 'src/map_item_id.dart';
export 'src/messages.g.dart'
    show
        PlatformLineCap,
        PlatformLineJoin,
        PlatformMapElevationStyle,
        PlatformMapEmphasisStyle,
        PlatformMapFeatureOptions,
        PlatformMapFeatureType,
        PlatformOverlayLevel,
        PlatformPointOfInterestCategory,
        PlatformUserTrackingMode;
export 'src/mk_annotation_icon.dart' hide MKAnnotationIconWire;
export 'src/mk_camera_zoom_range.dart' hide MKCameraZoomRangeWire;
export 'src/mk_circle.dart' hide MKCircleWire;
export 'src/mk_coordinate_region.dart' hide MKCoordinateRegionWire;
export 'src/mk_coordinate_span.dart' hide MKCoordinateSpanWire;
export 'src/mk_enums.dart';
export 'src/mk_map_camera.dart' hide MKMapCameraWire;
export 'src/mk_map_configuration.dart';
export 'src/mk_map_feature.dart' hide MKMapFeatureWire;
export 'src/mk_map_snapshot_options.dart' hide MKMapSnapshotOptionsWire;
export 'src/mk_map_view.dart' hide MKMapViewControllerOverride;
export 'src/mk_map_view_controller.dart'
    hide MKMapViewControllerImpl, MKMapViewEventSink;
export 'src/mk_point_annotation.dart' hide MKPointAnnotationWire;
export 'src/mk_point_of_interest_filter.dart' hide MKPointOfInterestFilterWire;
export 'src/mk_polygon.dart' hide MKPolygonWire;
export 'src/mk_polyline.dart' hide MKPolylineWire;
export 'src/mk_tile_overlay.dart' hide MKTileOverlayWire;
