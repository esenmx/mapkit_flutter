import CoreLocation
import Foundation
import MapKit

final class FlutterCircle: MKCircle, FlutterOverlay, @unchecked Sendable {
    var strokeColor: PlatformColor?
    var fillColor: PlatformColor?
    var isConsumingTapEvents: Bool = false
    var lineWidth: CGFloat = 1
    var isHidden: Bool = false
    var id: String = ""
    var zIndex: Int = 0
    var overlayLevel: MKOverlayLevel = .aboveRoads

    convenience init(fromPlatform data: PlatformCircle) {
        self.init(center: data.center.clCoordinate, radius: data.radius)
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
        let renderer = MKCircleRenderer(circle: self)
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

        if isHidden {
            return shapeLayer
        }
        #if os(iOS)
        let centerPoint = snapshot.point(for: coordinate)
        let offsetPoint = snapshot.point(for: coordinate.offsetLatitude(byMeters: radius))
        let radiusInPoints = centerPoint.y - offsetPoint.y

        let circlePath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radiusInPoints,
            startAngle: CGFloat(0),
            endAngle: CGFloat(Double.pi * 2),
            clockwise: true
        )

        shapeLayer.path = circlePath.cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor?.cgColor ?? PlatformColor.clear.cgColor
        shapeLayer.fillColor = fillColor?.cgColor ?? PlatformColor.clear.cgColor
        #endif
        return shapeLayer
    }
}

public extension MKCircle {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let circleRenderer = MKCircleRenderer(circle: self)
        let currentMapPoint: MKMapPoint = MKMapPoint(coordinate)
        let circleViewPoint: CGPoint = circleRenderer.point(for: currentMapPoint)
        if circleRenderer.path == nil {
          return false
        } else {
            return circleRenderer.path.contains(circleViewPoint)
        }
    }
}

private extension CLLocationCoordinate2D {
    /// A coordinate shifted north by `meters`, using the standard
    /// ~111,320 m-per-degree-of-latitude approximation. Used to size the
    /// circle in points when rendering map snapshots.
    func offsetLatitude(byMeters meters: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude + meters / 111_320, longitude: longitude)
    }
}
