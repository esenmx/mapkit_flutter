import Foundation
import MapKit

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

@MainActor
class TouchHandler {

    static func handleMapTaps(tap: PlatformGestureRecognizer, overlays: [MKOverlay], flutterApi: MapKitFlutterApi?, in view: MKMapView) {
        let locationInView = tap.location(in: view)
        let coord: CLLocationCoordinate2D = view.convert(locationInView, toCoordinateFrom: view)
        var didOverlayConsumeTapEvent = false
        for overlay: MKOverlay in overlays {
            if let polyline = overlay as? any StyledPolyline {
                if polyline.isConsumingTapEvents && polyline.contains(coordinate: coord, mapView: view) {
                    flutterApi?.onPolylineTap(polylineId: polyline.id) { _ in }
                    didOverlayConsumeTapEvent = true
                }
            } else if let polygon = overlay as? FlutterPolygon {
                if polygon.isConsumingTapEvents && polygon.contains(coordinate: coord) {
                    flutterApi?.onPolygonTap(polygonId: polygon.id) { _ in }
                    didOverlayConsumeTapEvent = true
                }
            } else if let circle = overlay as? FlutterCircle {
                if circle.isConsumingTapEvents && circle.contains(coordinate: coord) {
                    flutterApi?.onCircleTap(circleId: circle.id) { _ in }
                    didOverlayConsumeTapEvent = true
                }
            }
        }
        if !didOverlayConsumeTapEvent {
            flutterApi?.onMapTap(coordinate: .from(coord)) { _ in }
        }
    }
}
