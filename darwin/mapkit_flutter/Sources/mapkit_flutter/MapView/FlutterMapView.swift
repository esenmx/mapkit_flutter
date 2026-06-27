import CoreLocation
import Foundation
import MapKit

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import AppKit
import FlutterMacOS
#endif

class FlutterMapView: MKMapView, PlatformGestureRecognizerDelegate, CLLocationManagerDelegate {
    weak var flutterApi: MapKitFlutterApi?

    /// Camera handed over before the first layout pass; re-applied once the
    /// view has real bounds so MapKit doesn't resolve it against a zero rect.
    private var pendingCamera: MKMapCamera?

    fileprivate let locationManager = CLLocationManager()
    private var pendingUserLocationRequest = false

    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        registerDefaultAnnotationViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerDefaultAnnotationViews()
    }

    convenience init() {
        self.init(frame: CGRect.zero)
        self.locationManager.delegate = self
        initialiseTapGestureRecognizers()
    }

    private func registerDefaultAnnotationViews() {
        self.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "FlutterMarkerAnnotationView")
        self.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "FlutterCustomAnnotationView")
    }

    #if os(iOS)
    override func layoutSubviews() {
        super.layoutSubviews()
        reapplyPendingCamera()
    }
    #elseif os(macOS)
    override func layout() {
        super.layout()
        reapplyPendingCamera()
    }
    #endif

    private func reapplyPendingCamera() {
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
        #if os(iOS)
        // `showsUserTrackingButton` is the iOS-only MKMapView convenience.
        self.showsUserTrackingButton = config.showsUserTrackingButton
        #endif

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

        #if os(iOS)
        self.insetsLayoutMarginsFromSafeArea = config.insetsLayoutMarginsFromSafeArea
        // `selectableMapFeatures` / `MKMapFeatureOptions` are iOS-only.
        self.selectableMapFeatures = Self.mapFeatureOptions(config.selectableMapFeatures)
        #endif
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

    #if os(iOS)
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
    #endif

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
        #if os(iOS)
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
        #elseif os(macOS)
        // macOS MKMapView pans/zooms/rotates natively; only tap and long-press
        // need bridging to Flutter. Camera moves arrive via the delegate's
        // regionDidChange, so no per-gesture camera recognizers are needed.
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(onTap))
        clickGesture.delegate = self
        self.addGestureRecognizer(clickGesture)
        let pressGesture = NSPressGestureRecognizer(target: self, action: #selector(longTap))
        pressGesture.delegate = self
        self.addGestureRecognizer(pressGesture)
        #endif
    }

    #if os(iOS)
    @objc func onMapGesture(sender: UIGestureRecognizer) {
        self.flutterApi?.onCameraMove(camera: currentPlatformCamera()) { _ in }
    }
    #endif

    @objc func longTap(_ sender: PlatformGestureRecognizer) {
        guard sender.state == .began else { return }
        let locationInView = sender.location(in: self)
        let locationOnMap = self.convert(locationInView, toCoordinateFrom: self)
        self.flutterApi?.onMapLongPress(coordinate: .from(locationOnMap)) { _ in }
    }

    @objc func onTap(_ tap: PlatformGestureRecognizer) {
        #if os(iOS)
        guard tap.state == .recognized else { return }
        #endif
        TouchHandler.handleMapTaps(tap: tap, overlays: self.overlays, flutterApi: self.flutterApi, in: self)
    }

    func gestureRecognizer(_ gestureRecognizer: PlatformGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: PlatformGestureRecognizer) -> Bool {
        return true
    }
}

extension PlatformUserTrackingMode {
    var mkMode: MKUserTrackingMode {
        switch self {
        case .none: return .none
        case .follow: return .follow
        case .followWithHeading:
            #if os(iOS)
            return .followWithHeading
            #elseif os(macOS)
            // Heading-tracking is unavailable on macOS; fall back to follow.
            return .follow
            #endif
        }
    }
}
