import Foundation
import MapKit

/// Shared style surface for the two polyline classes. Straight lines subclass
/// `MKPolyline`; geodesic lines subclass `MKGeodesicPolyline` (which densifies
/// the great-circle path natively) — one class can't do both, so the
/// renderer/snapshot logic lives here once.
protocol StyledPolyline: MKPolyline, FlutterOverlay {
    var id: String { get set }
    var coordinates: [CLLocationCoordinate2D] { get set }
    var strokeColor: PlatformColor? { get set }
    var lineWidth: CGFloat { get set }
    var lineCapType: CGLineCap { get set }
    var lineJoinType: CGLineJoin { get set }
    var dashPattern: [NSNumber]? { get set }
    var gradientColors: [PlatformColor]? { get set }
    var isHidden: Bool { get set }
    var isConsumingTapEvents: Bool { get set }
    var zIndex: Int { get set }
    var overlayLevel: MKOverlayLevel { get set }
}

/// Builds the right polyline class for the wire payload.
@MainActor
func makeStyledPolyline(fromPlatform data: PlatformPolyline) -> any StyledPolyline {
    if data.isGeodesic {
        return FlutterGeodesicPolyline(fromPlatform: data)
    }
    return FlutterPolyline(fromPlatform: data)
}

extension StyledPolyline {
    func applyStyle(fromPlatform data: PlatformPolyline) {
        id = data.id
        coordinates = data.coordinates.map(\.clCoordinate)
        strokeColor = PlatformColor(argb: data.strokeColorArgb)
        lineWidth = CGFloat(data.lineWidth)
        lineCapType = data.lineCap.cgLineCap
        lineJoinType = data.lineJoin.cgLineJoin
        dashPattern = data.lineDashPattern.map { $0.map(NSNumber.init(value:)) }
        if let argb = data.gradientColorsArgb, argb.count >= 2 {
            gradientColors = argb.map { PlatformColor(argb: $0) }
        }
        isHidden = data.isHidden
        isConsumingTapEvents = data.consumeTapEvents
        zIndex = Int(data.zIndex)
        overlayLevel = data.level.mkLevel
    }

    func makeRenderer() -> MKOverlayRenderer {
        let renderer: MKPolylineRenderer
        if let gradientColors, gradientColors.count >= 2 {
            let locations = (0..<gradientColors.count).map { CGFloat($0) / CGFloat(gradientColors.count - 1) }
            let gradient = MKGradientPolylineRenderer(polyline: self)
            gradient.setColors(gradientColors, locations: locations)
            renderer = gradient
        } else {
            renderer = MKPolylineRenderer(polyline: self)
        }
        if isHidden {
            renderer.strokeColor = .clear
            renderer.lineWidth = 0.0
        } else {
            if gradientColors == nil { renderer.strokeColor = strokeColor }
            renderer.lineWidth = lineWidth
            renderer.lineDashPattern = dashPattern
            renderer.lineJoin = lineJoinType
            renderer.lineCap = lineCapType
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
            path.move(to: snapshot.point(for: coordinate))
        }

        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineCap = caShapeLayerLineCap
        shapeLayer.lineJoin = caShapeLayerLineJoin
        shapeLayer.lineDashPattern = dashPattern
        shapeLayer.strokeColor = strokeColor?.cgColor ?? PlatformColor.clear.cgColor
        shapeLayer.fillColor = PlatformColor.clear.cgColor
        #endif
        return shapeLayer
    }

    private var caShapeLayerLineCap: CAShapeLayerLineCap {
        switch lineCapType {
        case .butt: return .butt
        case .square: return .square
        case .round: return .round
        @unknown default: return .round
        }
    }

    private var caShapeLayerLineJoin: CAShapeLayerLineJoin {
        switch lineJoinType {
        case .round: return .round
        case .bevel: return .bevel
        case .miter: return .miter
        @unknown default: return .round
        }
    }
}

final class FlutterPolyline: MKPolyline, StyledPolyline, @unchecked Sendable {
    var id: String = ""
    var coordinates: [CLLocationCoordinate2D] = []
    var strokeColor: PlatformColor?
    var lineWidth: CGFloat = 1
    var lineCapType: CGLineCap = .round
    var lineJoinType: CGLineJoin = .round
    var dashPattern: [NSNumber]?
    var gradientColors: [PlatformColor]?
    var isHidden: Bool = false
    var isConsumingTapEvents: Bool = false
    var zIndex: Int = 0
    var overlayLevel: MKOverlayLevel = .aboveRoads

    convenience init(fromPlatform data: PlatformPolyline) {
        let points = data.coordinates.map(\.clCoordinate)
        self.init(coordinates: points, count: points.count)
        applyStyle(fromPlatform: data)
    }
}

/// Great-circle polyline (`MKGeodesicPolyline`) — MapKit densifies the path
/// natively, so `points()` already follows the arc for hit tests and drawing.
final class FlutterGeodesicPolyline: MKGeodesicPolyline, StyledPolyline, @unchecked Sendable {
    var id: String = ""
    var coordinates: [CLLocationCoordinate2D] = []
    var strokeColor: PlatformColor?
    var lineWidth: CGFloat = 1
    var lineCapType: CGLineCap = .round
    var lineJoinType: CGLineJoin = .round
    var dashPattern: [NSNumber]?
    var gradientColors: [PlatformColor]?
    var isHidden: Bool = false
    var isConsumingTapEvents: Bool = false
    var zIndex: Int = 0
    var overlayLevel: MKOverlayLevel = .aboveRoads

    convenience init(fromPlatform data: PlatformPolyline) {
        let points = data.coordinates.map(\.clCoordinate)
        self.init(coordinates: points, count: points.count)
        applyStyle(fromPlatform: data)
    }
}

public extension MKPolyline {
    // maxMeters is the preferred distance offset from the self to be acknowledged as a touch
    func contains(coordinate: CLLocationCoordinate2D, mapView: MKMapView, maxMeters: Int = 8) -> Bool {
        let distance: Double = distanceOf(pt: MKMapPoint.init(coordinate), toMultipPoint: self)
        return distance <= meters(fromPixel: maxMeters, at: coordinate, view: mapView)
    }

    private func distanceOf(pt: MKMapPoint, toMultipPoint multiPoint: MKMultiPoint) -> Double {
        // A line needs at least one segment; fewer than two points has no
        // distance and `0..<(pointCount - 1)` would trap for an empty line.
        guard multiPoint.pointCount > 1 else { return Double(MAXFLOAT) }
        var distance: Double = Double(MAXFLOAT)
        for n in 0..<multiPoint.pointCount - 1 {
            let ptA = multiPoint.points()[n]
            let ptB = multiPoint.points()[n + 1]
            let xDelta: Double = ptB.x - ptA.x
            let yDelta: Double = ptB.y - ptA.y
            if xDelta == 0.0 && yDelta == 0.0 {
                // Points must not be equal
                continue
            }
            let u: Double = ((pt.x - ptA.x) * xDelta + (pt.y - ptA.y) * yDelta) / (xDelta * xDelta + yDelta * yDelta)
            var ptClosest: MKMapPoint
            if u < 0.0 {
                ptClosest = ptA
            }
            else if u > 1.0 {
                ptClosest = ptB
            }
            else {
                ptClosest = MKMapPoint.init(x: ptA.x + u * xDelta, y: ptA.y + u * yDelta)
            }

            distance = min(distance, ptClosest.distance(to: pt))
        }
        return distance
    }

    private func meters(fromPixel pixel: Int, at touchCoordinate: CLLocationCoordinate2D, view: MKMapView) -> Double {
        let touchPoint: CGPoint = view.convert(touchCoordinate, toPointTo: view)
        let maxOffsetPoint = CGPoint(x: touchPoint.x + CGFloat(pixel), y: touchPoint.y)
        let maxOffsetCoordinate: CLLocationCoordinate2D = view.convert(maxOffsetPoint, toCoordinateFrom: view)
        return MKMapPoint.init(touchCoordinate).distance(to: MKMapPoint.init(maxOffsetCoordinate))
    }
}
