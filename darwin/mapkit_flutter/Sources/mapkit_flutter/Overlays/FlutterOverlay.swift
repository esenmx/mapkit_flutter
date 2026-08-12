import Foundation
import MapKit

/// Shared abstraction over the vector overlays (polyline, polygon, circle) so a
/// single CRUD path can manage all of them. Each conformer owns its own
/// renderer and snapshot drawing.
protocol FlutterOverlay: MKOverlay {
    var id: String { get }
    var zIndex: Int { get }
    var isConsumingTapEvents: Bool { get }
    var overlayLevel: MKOverlayLevel { get }
    func makeRenderer() -> MKOverlayRenderer
    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer
}

extension MKMapView {
    /// Adds an overlay, using `zIndex` as an ordering hint within its level:
    /// the overlay lands directly before the first Flutter overlay whose
    /// zIndex is greater than its own, so equal indices preserve insertion
    /// order. Non-Flutter peers (tile overlays) carry no zIndex and never
    /// shift the position; with no higher-zIndex peer the overlay is appended
    /// on top of the level.
    func addFlutterOverlay(_ overlay: any FlutterOverlay) {
        let level = overlay.overlayLevel
        let peers = self.overlays(in: level)
        let index = peers.firstIndex { peer in
            guard let flutterPeer = peer as? any FlutterOverlay else { return false }
            return flutterPeer.zIndex > overlay.zIndex
        }
        if let index {
            insertOverlay(overlay, at: index, level: level)
        } else {
            addOverlay(overlay, level: level)
        }
    }


}

extension PlatformOverlayLevel {
    var mkLevel: MKOverlayLevel {
        switch self {
        case .aboveRoads: return .aboveRoads
        case .aboveLabels: return .aboveLabels
        }
    }
}
