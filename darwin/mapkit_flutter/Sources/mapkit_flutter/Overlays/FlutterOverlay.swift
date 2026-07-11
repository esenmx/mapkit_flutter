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
    /// the overlay lands after every existing Flutter overlay whose zIndex is
    /// `<=` its own, so equal indices preserve insertion order. The insertion
    /// index is clamped to the level's array bounds.
    func addFlutterOverlay(_ overlay: any FlutterOverlay) {
        let level = overlay.overlayLevel
        let peers = self.overlays(in: level)
        let index = peers
            .compactMap { $0 as? any FlutterOverlay }
            .filter { $0.zIndex <= overlay.zIndex }
            .count
        if index >= peers.count {
            addOverlay(overlay, level: level)
        } else {
            insertOverlay(overlay, at: index, level: level)
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
