import Foundation
import MapKit

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

@MainActor
class TouchHandler {

    /// A tap on an annotation view selects the annotation; it is not a map tap.
    static func handleMapTaps(tap: PlatformGestureRecognizer, flutterApi: MapKitFlutterApi?, in view: MKMapView) {
        let locationInView = tap.location(in: view)
        guard !hitsAnnotationView(at: locationInView, in: view) else { return }
        let coord: CLLocationCoordinate2D = view.convert(locationInView, toCoordinateFrom: view)
        handleMapTap(at: coord, flutterApi: flutterApi, in: view)
    }

    /// Walks the subviews rather than hit-testing: macOS `MKMapView.hitTest`
    /// answers with the map itself.
    private static func hitsAnnotationView(at point: CGPoint, in view: MKMapView) -> Bool {
        func search(_ parent: PlatformView) -> Bool {
            parent.subviews.contains { child in
                guard !child.isHidden, child.platformAlpha > 0 else { return false }
                if child is MKAnnotationView {
                    return child.convert(child.bounds, to: view).contains(point)
                }
                return search(child)
            }
        }
        return search(view)
    }

    /// Fires only the top-most visible consuming overlay under the tap
    /// (`.aboveLabels`, then `.aboveRoads`, each top-first); otherwise the map tap.
    static func handleMapTap(at coord: CLLocationCoordinate2D, flutterApi: MapKitFlutterApi?, in view: MKMapView) {
        // Both levels list bottom-to-top, so the reversed concatenation is labels then roads, each top-first.
        // (A typed `a.reversed() + b.reversed()` is an ambiguous overload for Swift 6.2 / Xcode 26.)
        for overlay in (view.overlays(in: .aboveRoads) + view.overlays(in: .aboveLabels)).reversed() {
            if let polyline = overlay as? any StyledPolyline {
                // At least the visible stroke: half the line width either side,
                // never less than an 8-point finger slop.
                let tolerance = max(8, polyline.lineWidth / 2)
                guard !polyline.isHidden, polyline.isConsumingTapEvents,
                      polyline.contains(coordinate: coord, mapView: view, tolerance: tolerance) else { continue }
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
