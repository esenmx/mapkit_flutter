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

    /// Applies a pre-diffed overlay update for one kind of overlay, selected
    /// by `isKind`. The Dart side already computed the add/change/remove sets,
    /// so a change is just a remove-by-id followed by a re-add — no equality
    /// re-check needed here.
    func applyOverlayUpdate(
        adding: [any FlutterOverlay],
        changing: [any FlutterOverlay],
        removing: Set<String>,
        ofKind isKind: (MKOverlay) -> Bool
    ) {
        let existing = overlays.filter(isKind).compactMap { $0 as? any FlutterOverlay }
        for overlay in existing where removing.contains(overlay.id) {
            removeOverlay(overlay)
        }
        for new in changing {
            if let old = existing.first(where: { $0.id == new.id }) {
                removeOverlay(old)
            }
            addFlutterOverlay(new)
        }
        for new in adding {
            addFlutterOverlay(new)
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
