import Foundation
import MapKit

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

@MainActor
class TouchHandler {

    static func handleMapTaps(tap: PlatformGestureRecognizer, flutterApi: MapKitFlutterApi?, in view: MKMapView) {
        let locationInView = tap.location(in: view)
        let coord: CLLocationCoordinate2D = view.convert(locationInView, toCoordinateFrom: view)
        handleMapTap(at: coord, flutterApi: flutterApi, in: view)
    }

    /// Fires only the top-most visible consuming overlay under the tap
    /// (`.aboveLabels`, then `.aboveRoads`, each top-first); otherwise the map tap.
    static func handleMapTap(at coord: CLLocationCoordinate2D, flutterApi: MapKitFlutterApi?, in view: MKMapView) {
        let topFirst: [MKOverlay] = view.overlays(in: .aboveLabels).reversed() + view.overlays(in: .aboveRoads).reversed()
        for overlay in topFirst {
            if let polyline = overlay as? any StyledPolyline {
                guard !polyline.isHidden, polyline.isConsumingTapEvents,
                      polyline.contains(coordinate: coord, mapView: view) else { continue }
                let id = polyline.id
                flutterApi?.send { try await $0.onPolylineTap(polylineId: id) }
                return
            } else if let polygon = overlay as? FlutterPolygon {
                guard !polygon.isHidden, polygon.isConsumingTapEvents, polygon.contains(coordinate: coord) else { continue }
                let id = polygon.id
                flutterApi?.send { try await $0.onPolygonTap(polygonId: id) }
                return
            } else if let circle = overlay as? FlutterCircle {
                guard !circle.isHidden, circle.isConsumingTapEvents, circle.contains(coordinate: coord) else { continue }
                let id = circle.id
                flutterApi?.send { try await $0.onCircleTap(circleId: id) }
                return
            }
        }
        let coordinate = PlatformCoordinate.from(coord)
        flutterApi?.send { try await $0.onMapTap(coordinate: coordinate) }
    }
}
