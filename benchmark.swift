import Foundation
import MapKit

protocol FlutterOverlay: MKOverlay {
    var id: String { get }
    var zIndex: Int { get }
    var isConsumingTapEvents: Bool { get }
    var overlayLevel: MKOverlayLevel { get }
    func makeRenderer() -> MKOverlayRenderer
    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer
}

extension MKMapView {
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

class DummyOverlay: NSObject, MKOverlay, FlutterOverlay {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var boundingMapRect: MKMapRect = MKMapRect()
    var id: String
    var zIndex: Int = 0
    var isConsumingTapEvents: Bool = false
    var overlayLevel: MKOverlayLevel = .aboveRoads

    init(id: String) {
        self.id = id
    }

    func makeRenderer() -> MKOverlayRenderer {
        return MKOverlayRenderer(overlay: self)
    }
    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer {
        return CAShapeLayer()
    }
}

let mapView = MKMapView()

// Populate
let numOverlays = 5000
for i in 0..<numOverlays {
    mapView.addOverlay(DummyOverlay(id: "id_\(i)"))
}

// Changing overlays
var changing = [any FlutterOverlay]()
for i in 0..<numOverlays {
    changing.append(DummyOverlay(id: "id_\(i)"))
}

let start = CFAbsoluteTimeGetCurrent()

mapView.applyOverlayUpdate(
    adding: [],
    changing: changing,
    removing: Set<String>(),
    ofKind: { _ in true }
)

let end = CFAbsoluteTimeGetCurrent()
print("Elapsed time: \(end - start) seconds")
