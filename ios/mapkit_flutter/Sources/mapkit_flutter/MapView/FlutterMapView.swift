import CoreLocation
import Flutter
import Foundation
import MapKit

class FlutterMapView: MKMapView, UIGestureRecognizerDelegate, @preconcurrency CLLocationManagerDelegate {
    weak var flutterApi: MapKitFlutterApi?

    /// Camera handed over before the first layout pass; re-applied once the
    /// view has real bounds so MapKit doesn't resolve it against a zero rect.
    private var pendingCamera: MKMapCamera?

    fileprivate let locationManager = CLLocationManager()
    private var pendingUserLocationRequest = false

    convenience init() {
        self.init(frame: CGRect.zero)
        self.locationManager.delegate = self
        initialiseTapGestureRecognizers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != .zero, let camera = pendingCamera {
            pendingCamera = nil
            setCamera(camera, animated: false)
        }
    }

    // MARK: - Camera

    func setInitialCamera(_ camera: PlatformMapCamera) {
        let mkCamera = camera.mkCamera
        if bounds.size == .zero {
            pendingCamera = mkCamera
        }
        setCamera(mkCamera, animated: false)
    }

    func currentPlatformCamera() -> PlatformMapCamera {
        return .from(self.camera)
    }

    func currentPlatformRegion() -> PlatformCoordinateRegion {
        guard bounds.size != .zero else {
            return PlatformCoordinateRegion(
                center: PlatformCoordinate(latitude: 0, longitude: 0),
                span: PlatformCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0)
            )
        }
        return .from(self.region)
    }

    // MARK: - Configuration

    func apply(configuration config: PlatformMapConfiguration) {
        applyMapConfiguration(config)

        self.showsCompass = config.showsCompass
        self.showsScale = config.showsScale

        self.isRotateEnabled = config.isRotateEnabled
        self.isScrollEnabled = config.isScrollEnabled
        self.isPitchEnabled = config.isPitchEnabled
        self.isZoomEnabled = config.isZoomEnabled

        if config.showsUserLocation {
            self.requestUserLocation()
        } else {
            self.removeUserLocation()
        }
        self.showsUserTrackingButton = config.showsUserTrackingButton

        self.setUserTrackingMode(config.userTrackingMode.mkMode, animated: false)

        // Always assign — nil clears a previously-set range/boundary.
        if let range = config.cameraZoomRange,
           range.minCenterCoordinateDistance != nil || range.maxCenterCoordinateDistance != nil {
            self.cameraZoomRange = MKMapView.CameraZoomRange(
                minCenterCoordinateDistance: range.minCenterCoordinateDistance ?? MKMapCameraZoomDefault,
                maxCenterCoordinateDistance: range.maxCenterCoordinateDistance ?? MKMapCameraZoomDefault
            )
        } else {
            self.cameraZoomRange = nil
        }
        self.cameraBoundary = config.cameraBoundary.flatMap {
            MKMapView.CameraBoundary(coordinateRegion: $0.mkRegion)
        }

        self.insetsLayoutMarginsFromSafeArea = config.insetsLayoutMarginsFromSafeArea
        self.selectableMapFeatures = Self.mapFeatureOptions(config.selectableMapFeatures)
    }

    private func applyMapConfiguration(_ config: PlatformMapConfiguration) {
        let elevationStyle: MKMapConfiguration.ElevationStyle =
            config.elevationStyle == .realistic ? .realistic : .flat

        switch config.kind {
        case .imagery:
            let configuration = MKImageryMapConfiguration()
            configuration.elevationStyle = elevationStyle
            self.preferredConfiguration = configuration
        case .hybrid:
            let configuration = MKHybridMapConfiguration()
            configuration.elevationStyle = elevationStyle
            if let filter = poiFilter(from: config.pointOfInterestFilter) {
                configuration.pointOfInterestFilter = filter
            }
            configuration.showsTraffic = config.showsTraffic
            self.preferredConfiguration = configuration
        case .standard:
            let configuration = MKStandardMapConfiguration()
            configuration.elevationStyle = elevationStyle
            if config.emphasisStyle == .muted {
                configuration.emphasisStyle = .muted
            }
            if let filter = poiFilter(from: config.pointOfInterestFilter) {
                configuration.pointOfInterestFilter = filter
            }
            configuration.showsTraffic = config.showsTraffic
            self.preferredConfiguration = configuration
        }
    }

    private func poiFilter(from filter: PlatformPointOfInterestFilter?) -> MKPointOfInterestFilter? {
        guard let filter = filter else { return nil }
        switch filter.mode {
        case .none:
            return MKPointOfInterestFilter.excludingAll
        case .all:
            return MKPointOfInterestFilter.includingAll
        case .including:
            return MKPointOfInterestFilter(including: filter.categories.compactMap(\.mkCategory))
        case .excluding:
            return MKPointOfInterestFilter(excluding: filter.categories.compactMap(\.mkCategory))
        }
    }

    private static func mapFeatureOptions(_ features: [PlatformMapFeatureOptions]) -> MKMapFeatureOptions {
        var options: MKMapFeatureOptions = []
        for feature in features {
            switch feature {
            case .pointsOfInterest: options.insert(.pointsOfInterest)
            case .territories: options.insert(.territories)
            case .physicalFeatures: options.insert(.physicalFeatures)
            }
        }
        return options
    }

    // MARK: - Location

    /// `showsUserLocation` runs MapKit's own Core Location session for the
    /// blue dot; the manager here exists only to fire the when-in-use prompt,
    /// which the view never requests itself. Outside `.notDetermined` the
    /// flag is set even when authorization is denied, so the view attempts,
    /// fails, and reports through
    /// `mapView(_:didFailToLocateUserWithError:)`.
    func requestUserLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            pendingUserLocationRequest = true
            locationManager.requestWhenInUseAuthorization()
        } else {
            self.showsUserLocation = true
        }
    }

    func removeUserLocation() {
        pendingUserLocationRequest = false
        self.showsUserLocation = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard pendingUserLocationRequest, manager.authorizationStatus != .notDetermined else { return }
        pendingUserLocationRequest = false
        self.showsUserLocation = true
    }

    /// Flutter annotations sorted bottom-to-top, matching their on-map
    /// stacking, for snapshot drawing.
    func getMapViewAnnotations() -> [FlutterAnnotation] {
        let flutter = self.annotations.compactMap { $0 as? FlutterAnnotation }
        return flutter.sorted(by: { $0.zPriority < $1.zPriority })
    }

    // MARK: - Gestures

    private func initialiseTapGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onMapGesture))
        panGesture.maximumNumberOfTouches = 2
        panGesture.delegate = self
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(onMapGesture))
        pinchGesture.delegate = self
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(onMapGesture))
        rotateGesture.delegate = self
        let tiltGesture = UISwipeGestureRecognizer(target: self, action: #selector(onMapGesture))
        tiltGesture.numberOfTouchesRequired = 2
        tiltGesture.direction = [.up, .down]
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: nil)
        doubleTapGesture.numberOfTapsRequired = 2
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGesture.require(toFail: doubleTapGesture)
        self.addGestureRecognizer(panGesture)
        self.addGestureRecognizer(pinchGesture)
        self.addGestureRecognizer(rotateGesture)
        self.addGestureRecognizer(tiltGesture)
        self.addGestureRecognizer(longTapGesture)
        self.addGestureRecognizer(doubleTapGesture)
        self.addGestureRecognizer(tapGesture)
    }

    @objc func onMapGesture(sender: UIGestureRecognizer) {
        self.flutterApi?.onCameraMove(camera: currentPlatformCamera()) { _ in }
    }

    @objc func longTap(sender: UIGestureRecognizer) {
        guard sender.state == .began else { return }
        let locationInView = sender.location(in: self)
        let locationOnMap = self.convert(locationInView, toCoordinateFrom: self)
        self.flutterApi?.onMapLongPress(coordinate: .from(locationOnMap)) { _ in }
    }

    @objc func onTap(tap: UITapGestureRecognizer) {
        if tap.state == .recognized {
            TouchHandler.handleMapTaps(tap: tap, overlays: self.overlays, flutterApi: self.flutterApi, in: self)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension PlatformUserTrackingMode {
    var mkMode: MKUserTrackingMode {
        switch self {
        case .none: return .none
        case .follow: return .follow
        case .followWithHeading: return .followWithHeading
        }
    }
}
