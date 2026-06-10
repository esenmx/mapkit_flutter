import CoreLocation
import Foundation
import MapKit

// Bridging between the pigeon-generated `Platform*` wire types and their real
// MapKit/CoreGraphics counterparts. The wire types keep a `Platform` prefix so
// the generated Swift never shadows Apple symbols; these extensions are the
// single place the two vocabularies meet.

extension PlatformCoordinate {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func from(_ coordinate: CLLocationCoordinate2D) -> PlatformCoordinate {
        PlatformCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

extension PlatformCoordinateRegion {
    var mkRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: center.clCoordinate,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta,
                longitudeDelta: span.longitudeDelta
            )
        )
    }

    static func from(_ region: MKCoordinateRegion) -> PlatformCoordinateRegion {
        PlatformCoordinateRegion(
            center: .from(region.center),
            span: PlatformCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta,
                longitudeDelta: region.span.longitudeDelta
            )
        )
    }
}

extension PlatformMapCamera {
    var mkCamera: MKMapCamera {
        MKMapCamera(
            lookingAtCenter: centerCoordinate.clCoordinate,
            fromDistance: distance,
            pitch: pitch,
            heading: heading
        )
    }

    static func from(_ camera: MKMapCamera) -> PlatformMapCamera {
        PlatformMapCamera(
            centerCoordinate: .from(camera.centerCoordinate),
            distance: camera.centerCoordinateDistance,
            heading: camera.heading,
            pitch: Double(camera.pitch)
        )
    }
}

extension PlatformLineCap {
    var cgLineCap: CGLineCap {
        switch self {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
}

extension PlatformLineJoin {
    var cgLineJoin: CGLineJoin {
        switch self {
        case .miter: return .miter
        case .round: return .round
        case .bevel: return .bevel
        }
    }
}
