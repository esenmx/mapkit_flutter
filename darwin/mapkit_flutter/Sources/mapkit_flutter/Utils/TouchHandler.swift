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
                    let id = polyline.id
                    flutterApi?.send { try await $0.onPolylineTap(polylineId: id) }
                    didOverlayConsumeTapEvent = true
                }
            } else if let polygon = overlay as? FlutterPolygon {
                if polygon.isConsumingTapEvents && polygon.contains(coordinate: coord) {
                    let id = polygon.id
                    flutterApi?.send { try await $0.onPolygonTap(polygonId: id) }
                    didOverlayConsumeTapEvent = true
                }
            } else if let circle = overlay as? FlutterCircle {
                if circle.isConsumingTapEvents && circle.contains(coordinate: coord) {
                    let id = circle.id
                    flutterApi?.send { try await $0.onCircleTap(circleId: id) }
                    didOverlayConsumeTapEvent = true
                }
            }
        }
        if !didOverlayConsumeTapEvent {
            let coordinate = PlatformCoordinate.from(coord)
            flutterApi?.send { try await $0.onMapTap(coordinate: coordinate) }
        }
    }
}
