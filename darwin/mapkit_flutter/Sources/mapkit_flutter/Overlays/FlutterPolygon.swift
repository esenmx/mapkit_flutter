import Foundation
import MapKit

final class FlutterPolygon: MKPolygon, FlutterOverlay, @unchecked Sendable {
    var strokeColor: PlatformColor?
    var fillColor: PlatformColor?
    var isConsumingTapEvents: Bool = false
    var lineWidth: CGFloat = 1
    var isHidden: Bool = false
    var id: String = ""
    var zIndex: Int = 0
    var coordinates: [CLLocationCoordinate2D] = []
    var overlayLevel: MKOverlayLevel = .aboveRoads

    convenience init(fromPlatform data: PlatformPolygon) {
        let outerPoints = data.coordinates.map(\.clCoordinate)
        let interiorPolygons = data.interiorPolygons.compactMap { ring -> MKPolygon? in
            let coords = ring.map(\.clCoordinate)
            guard !coords.isEmpty else { return nil }
            return MKPolygon(coordinates: coords, count: coords.count)
        }
        self.init(coordinates: outerPoints, count: outerPoints.count, interiorPolygons: interiorPolygons)
        self.coordinates = outerPoints
        self.strokeColor = PlatformColor(argb: data.strokeColorArgb)
        self.fillColor = PlatformColor(argb: data.fillColorArgb)
        self.isConsumingTapEvents = data.consumeTapEvents
        self.lineWidth = CGFloat(data.lineWidth)
        self.id = data.id
        self.isHidden = data.isHidden
        self.zIndex = Int(data.zIndex)
        self.overlayLevel = data.level.mkLevel
    }

    func makeRenderer() -> MKOverlayRenderer {
        let renderer = MKPolygonRenderer(polygon: self)
        if isHidden {
            renderer.strokeColor = .clear
            renderer.lineWidth = 0.0
        } else {
            renderer.strokeColor = strokeColor
            renderer.fillColor = fillColor
            renderer.lineWidth = lineWidth
        }
        return renderer
    }

    func getCAShapeLayer(snapshot: MKMapSnapshotter.Snapshot) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        #if os(iOS)
        let path = UIBezierPath()

        guard !isHidden, let first = coordinates.first else {
            return shapeLayer
        }

        path.move(to: snapshot.point(for: first))
        for coordinate in coordinates {
            path.addLine(to: snapshot.point(for: coordinate))
        }

        path.addLine(to: snapshot.point(for: first))
        path.close()

        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor?.cgColor ?? PlatformColor.clear.cgColor
        shapeLayer.fillColor = fillColor?.cgColor ?? PlatformColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        #endif
        return shapeLayer
    }
}

public extension MKPolygon {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        guard pointCount > 0 else { return false }
        let path = CGMutablePath()
        let pts = points()
        path.move(to: CGPoint(x: pts[0].x, y: pts[0].y))
        for i in 1..<pointCount {
            path.addLine(to: CGPoint(x: pts[i].x, y: pts[i].y))
        }
        path.closeSubpath()

        if let interiorPolygons = self.interiorPolygons {
            for hole in interiorPolygons {
                if hole.contains(coordinate: coordinate) {
                    return false
                }
            }
        }

        let mapPoint = MKMapPoint(coordinate)
        return path.contains(CGPoint(x: mapPoint.x, y: mapPoint.y))
    }
}
