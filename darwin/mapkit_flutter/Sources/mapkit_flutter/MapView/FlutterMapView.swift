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

// `@preconcurrency`: CLLocationManagerDelegate is nonisolated, but callbacks
// arrive on the thread that created the manager — main, since the manager is
// an instance property of this MainActor-isolated view.
class FlutterMapView: MKMapView, PlatformGestureRecognizerDelegate, @preconcurrency CLLocationManagerDelegate {
    weak var flutterApi: MapKitFlutterApi?

    /// Camera handed over before the first layout pass; re-applied once the
    /// view has real bounds so MapKit doesn't resolve it against a zero rect.
    private var pendingCamera: MKMapCamera?

    fileprivate let locationManager = CLLocationManager()
    private var pendingUserLocationRequest = false

    /// The last configuration Dart pushed.
    private(set) var appliedConfiguration: PlatformMapConfiguration?

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
        let previousTrackingMode = appliedConfiguration?.userTrackingMode
        appliedConfiguration = config
        self.preferredConfiguration = Self.makeMapConfiguration(config)

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

        // MapKit drops to `.none` when the user pans; unrelated config changes must not snap back.
        if config.userTrackingMode != previousTrackingMode {
            self.setUserTrackingMode(config.userTrackingMode.mkMode, animated: false)
        }

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

    /// The `MKMapConfiguration` for a Dart configuration; shared by the live map and snapshots.
    nonisolated static func makeMapConfiguration(
        _ config: PlatformMapConfiguration,
        hidingPointsOfInterest: Bool = false
    ) -> MKMapConfiguration {
        let elevationStyle: MKMapConfiguration.ElevationStyle =
            config.elevationStyle == .realistic ? .realistic : .flat
        let filter = hidingPointsOfInterest ? .excludingAll : poiFilter(from: config.pointOfInterestFilter)

        switch config.kind {
        case .imagery:
            let configuration = MKImageryMapConfiguration()
            configuration.elevationStyle = elevationStyle
            return configuration
        case .hybrid:
            let configuration = MKHybridMapConfiguration()
            configuration.elevationStyle = elevationStyle
            if let filter {
                configuration.pointOfInterestFilter = filter
            }
            configuration.showsTraffic = config.showsTraffic
            return configuration
        case .standard:
            let configuration = MKStandardMapConfiguration()
            configuration.elevationStyle = elevationStyle
            if config.emphasisStyle == .muted {
                configuration.emphasisStyle = .muted
            }
            if let filter {
                configuration.pointOfInterestFilter = filter
            }
            configuration.showsTraffic = config.showsTraffic
            return configuration
        }
    }

    private nonisolated static func poiFilter(from filter: PlatformPointOfInterestFilter?) -> MKPointOfInterestFilter? {
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

    /// Detaches every delegate and drops map content so the view holds nothing after `dispose`.
    func tearDown() {
        delegate = nil
        flutterApi = nil
        locationManager.delegate = nil
        removeUserLocation()
        removeAnnotations(annotations)
        removeOverlays(overlays)
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
        // Camera moves arrive via the delegate (`mapViewDidChangeVisibleRegion`).
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: nil)
        doubleTapGesture.numberOfTapsRequired = 2
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        tapGesture.require(toFail: doubleTapGesture)
        self.addGestureRecognizer(longTapGesture)
        self.addGestureRecognizer(doubleTapGesture)
        self.addGestureRecognizer(tapGesture)
        #elseif os(macOS)
        // macOS MKMapView pans/zooms/rotates natively; only tap and long-press
        // need bridging to Flutter. Camera moves arrive via the delegate.
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(onTap))
        clickGesture.delegate = self
        self.addGestureRecognizer(clickGesture)
        let pressGesture = NSPressGestureRecognizer(target: self, action: #selector(longTap))
        pressGesture.delegate = self
        self.addGestureRecognizer(pressGesture)
        #endif
    }

    @objc func longTap(_ sender: PlatformGestureRecognizer) {
        guard sender.state == .began else { return }
        let locationInView = sender.location(in: self)
        let locationOnMap = self.convert(locationInView, toCoordinateFrom: self)
        let coordinate = PlatformCoordinate.from(locationOnMap)
        self.flutterApi?.send { try await $0.onMapLongPress(coordinate: coordinate) }
    }

    @objc func onTap(_ tap: PlatformGestureRecognizer) {
        #if os(iOS)
        guard tap.state == .recognized else { return }
        #endif
        TouchHandler.handleMapTaps(tap: tap, flutterApi: self.flutterApi, in: self)
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
