import Foundation
import MapKit

#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import AppKit
import FlutterMacOS
#endif

/// Hosts one `MKMapView` platform view and implements the pigeon-generated
/// `MapKitHostApi`, mirroring `MKMapView`'s imperative surface
/// (setCamera/setRegion/setCenter, camera/region reads, conversions).
///
/// On iOS this object is itself the `FlutterPlatformView` (see the extension
/// below); on macOS the factory wraps it in a `MapKitContainerView` `NSView`.
@MainActor
public class MapKitViewHost: NSObject, @preconcurrency MapKitHostApi {
    #if os(iOS)
    var contentView: UIView
    #endif
    var mapView: FlutterMapView
    var registrar: FlutterPluginRegistrar
    var flutterApi: MapKitFlutterApi
    var currentlySelectedAnnotation: String?
    var tileOverlays: [String: FlutterTileOverlay] = [:]
    var annotationsById: [String: FlutterAnnotation] = [:]
    private var overlaysById: [String: any FlutterOverlay] = [:]

    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64) {
        let suffix = "\(id)"
        #if os(iOS)
        let messenger = registrar.messenger()
        #elseif os(macOS)
        let messenger = registrar.messenger
        #endif
        self.registrar = registrar
        self.flutterApi = MapKitFlutterApi(binaryMessenger: messenger, messageChannelSuffix: suffix)
        self.mapView = FlutterMapView()

        #if os(iOS)
        // To stop the odd movement of the Apple logo.
        self.contentView = UIScrollView()
        self.contentView.addSubview(mapView)
        mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        #endif

        super.init()

        self.mapView.delegate = self
        self.mapView.flutterApi = self.flutterApi
        MapKitHostApiSetup.setUp(binaryMessenger: messenger, api: self, messageChannelSuffix: suffix)
    }

    private func mapKitError(_ code: String, _ message: String) -> MapKitHostError {
        return MapKitHostError(code: code, message: message, details: nil)
    }

    // MARK: - MapKitHostApi

    func initialize(params: PlatformMapViewCreationParams) throws {
        self.mapView.apply(configuration: params.configuration)
        self.mapView.setInitialCamera(params.initialCamera)
        self.annotationsToAdd(params.annotations)
        params.polylines.forEach { self.addOverlay(makeStyledPolyline(fromPlatform: $0)) }
        params.polygons.forEach { self.addOverlay(FlutterPolygon(fromPlatform: $0)) }
        params.circles.forEach { self.addOverlay(FlutterCircle(fromPlatform: $0)) }
    }

    func setCamera(camera: PlatformMapCamera, animated: Bool) throws {
        self.mapView.setCamera(camera.mkCamera, animated: animated)
    }

    func setRegion(region: PlatformCoordinateRegion, animated: Bool) throws {
        self.mapView.setRegion(region.mkRegion, animated: animated)
    }

    func setCenter(coordinate: PlatformCoordinate, animated: Bool) throws {
        self.mapView.setCenter(coordinate.clCoordinate, animated: animated)
    }

    func getCamera() throws -> PlatformMapCamera {
        return self.mapView.currentPlatformCamera()
    }

    func getRegion() throws -> PlatformCoordinateRegion {
        return self.mapView.currentPlatformRegion()
    }

    func convertToPoint(coordinate: PlatformCoordinate) throws -> PlatformPoint? {
        guard self.mapView.bounds.size != .zero else { return nil }
        let point = self.mapView.convert(coordinate.clCoordinate, toPointTo: self.mapView)
        return PlatformPoint(x: Double(point.x), y: Double(point.y))
    }

    func convertToCoordinate(point: PlatformPoint) throws -> PlatformCoordinate? {
        guard self.mapView.bounds.size != .zero else { return nil }
        let coordinate = self.mapView.convert(
            CGPoint(x: point.x, y: point.y),
            toCoordinateFrom: self.mapView
        )
        return .from(coordinate)
    }

    func updateAnnotations(toAdd: [PlatformAnnotation], toChange: [PlatformAnnotation], idsToRemove: [String]) throws {
        if !toAdd.isEmpty { self.annotationsToAdd(toAdd) }
        if !toChange.isEmpty { self.annotationsToChange(toChange) }
        if !idsToRemove.isEmpty { self.annotationsToRemove(idsToRemove) }
    }

    func updatePolylines(toAdd: [PlatformPolyline], toChange: [PlatformPolyline], idsToRemove: [String]) throws {
        self.applyOverlayUpdate(
            adding: toAdd.map { makeStyledPolyline(fromPlatform: $0) },
            changing: toChange.map { makeStyledPolyline(fromPlatform: $0) },
            removing: idsToRemove)
    }

    func updatePolygons(toAdd: [PlatformPolygon], toChange: [PlatformPolygon], idsToRemove: [String]) throws {
        self.applyOverlayUpdate(
            adding: toAdd.map(FlutterPolygon.init(fromPlatform:)),
            changing: toChange.map(FlutterPolygon.init(fromPlatform:)),
            removing: idsToRemove)
    }

    func updateCircles(toAdd: [PlatformCircle], toChange: [PlatformCircle], idsToRemove: [String]) throws {
        self.applyOverlayUpdate(
            adding: toAdd.map(FlutterCircle.init(fromPlatform:)),
            changing: toChange.map(FlutterCircle.init(fromPlatform:)),
            removing: idsToRemove)
    }

    func updateMapConfiguration(configuration: PlatformMapConfiguration) throws {
        self.mapView.apply(configuration: configuration)
    }

    func showCallout(annotationId: String) throws {
        self.selectAnnotation(with: annotationId)
    }

    func hideCallout(annotationId: String) throws {
        self.hideAnnotation(with: annotationId)
    }

    func isCalloutShown(annotationId: String) throws -> Bool {
        return self.isAnnotationSelected(with: annotationId)
    }

    func takeSnapshot(options: PlatformSnapshotOptions, completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        Task { @MainActor in
            do {
                guard let data = try await self.takeSnapshot(options: options) else {
                    completion(.failure(self.mapKitError("snapshot-failed", "Snapshot produced no image data.")))
                    return
                }
                completion(.success(data))
            } catch {
                completion(.failure(self.mapKitError("snapshot-failed", error.localizedDescription)))
            }
        }
    }

    func openLookAround(coordinate: PlatformCoordinate, completion: @escaping (Result<Bool, Error>) -> Void) {
        #if os(iOS)
        let coord = coordinate.clCoordinate
        Task { @MainActor in
            let request = MKLookAroundSceneRequest(coordinate: coord)
            do {
                guard let scene = try await request.scene else {
                    completion(.success(false))
                    return
                }
                let vc = MKLookAroundViewController(scene: scene)
                let host = self.contentView.window?.rootViewController
                    ?? UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                        .first
                guard let host = host else {
                    completion(.success(false))
                    return
                }
                let presenter = host.presentedViewController ?? host
                presenter.present(vc, animated: true) {
                    completion(.success(true))
                }
            } catch {
                completion(.success(false))
            }
        }
        #elseif os(macOS)
        // Look Around (MKLookAroundViewController) is unavailable on macOS.
        completion(.success(false))
        #endif
    }

    func addTileOverlay(overlay overlayData: PlatformTileOverlay) throws {
        let overlay = FlutterTileOverlay(fromPlatform: overlayData)
        if !overlay.id.isEmpty, tileOverlays[overlay.id] != nil {
            try removeTileOverlay(tileOverlayId: overlay.id)
        }
        tileOverlays[overlay.id] = overlay
        self.mapView.addOverlay(overlay, level: overlay.overlayLevel)
    }

    func removeTileOverlay(tileOverlayId: String) throws {
        guard let overlay = tileOverlays.removeValue(forKey: tileOverlayId) else { return }
        self.mapView.removeOverlay(overlay)
    }

    private func addOverlay(_ overlay: any FlutterOverlay) {
        self.overlaysById[overlay.id] = overlay
        self.mapView.addFlutterOverlay(overlay)
    }

    private func applyOverlayUpdate(adding: [any FlutterOverlay], changing: [any FlutterOverlay], removing: [String]) {
        for id in removing {
            if let overlay = self.overlaysById.removeValue(forKey: id) {
                self.mapView.removeOverlay(overlay)
            }
        }
        for new in changing {
            if let old = self.overlaysById[new.id] {
                self.mapView.removeOverlay(old)
            }
            self.addOverlay(new)
        }
        for new in adding {
            self.addOverlay(new)
        }
    }
}

extension MapKitViewHost: MKMapViewDelegate {
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if self.mapView.bounds.size != .zero {
            self.flutterApi.onCameraMove(camera: self.mapView.currentPlatformCamera()) { _ in }
        }
        self.flutterApi.onCameraIdle { _ in }
    }

    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.flutterApi.onCameraMoveStarted { _ in }
    }

    // Annotation drag lifecycle.
    public func mapView(_ mapView: MKMapView,
                        annotationView view: MKAnnotationView,
                        didChange newState: MKAnnotationView.DragState,
                        fromOldState oldState: MKAnnotationView.DragState) {
        guard let annotation = view.annotation as? FlutterAnnotation else { return }
        let id = annotation.id
        let coordinate = PlatformCoordinate.from(annotation.coordinate)
        switch newState {
        case .starting:
            self.flutterApi.onAnnotationDragStart(annotationId: id, coordinate: coordinate) { _ in }
        case .dragging:
            self.flutterApi.onAnnotationDrag(annotationId: id, coordinate: coordinate) { _ in }
        case .ending, .canceling:
            annotation.wasDragged = true
            self.flutterApi.onAnnotationDragEnd(annotationId: id, coordinate: coordinate) { _ in }
        default:
            break
        }
    }

    public func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        self.flutterApi.onDidFailLoadingMap(error: error.localizedDescription) { _ in }
    }

    public func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        self.flutterApi.onDidFailToLocateUser(error: error.localizedDescription) { _ in }
    }

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tile = overlay as? FlutterTileOverlay {
            let renderer = MKTileOverlayRenderer(tileOverlay: tile)
            renderer.alpha = tile.alpha
            return renderer
        }
        return (overlay as? any FlutterOverlay)?.makeRenderer() ?? MKOverlayRenderer()
    }
}

extension MapKitViewHost {
    private func takeSnapshot(options: PlatformSnapshotOptions) async throws -> FlutterStandardTypedData? {
        let snapshotOptions = MKMapSnapshotter.Options()
        snapshotOptions.region = self.mapView.region
        snapshotOptions.size = self.mapView.frame.size
        #if os(iOS)
        snapshotOptions.scale = PlatformScreen.scale
        #endif
        snapshotOptions.showsBuildings = options.showsBuildings
        snapshotOptions.pointOfInterestFilter = options.showsPointsOfInterest ? .includingAll : .excludingAll

        let snapshotter = MKMapSnapshotter(options: snapshotOptions)
        let snapshot = try await snapshotter.start()

        #if os(iOS)
        let image = UIGraphicsImageRenderer(size: snapshotOptions.size).image { context in
            snapshot.image.draw(at: .zero)
            let rect = snapshotOptions.mapRect
            if options.showsAnnotations {
                for annotation in self.mapView.getMapViewAnnotations() where !annotation.isHidden {
                    self.drawAnnotations(annotation: annotation, point: snapshot.point(for: annotation.coordinate))
                }
            }
            if options.showsOverlays {
                for overlay in self.mapView.overlays {
                    if overlay.intersects?(rect) ?? overlay.boundingMapRect.intersects(rect) {
                        self.drawOverlays(overlay: overlay, snapshot: snapshot, context: context)
                    }
                }
            }
        }
        guard let imageData = image.pngRepresentation else {
            return nil
        }
        #elseif os(macOS)
        // macOS renders the base map image; annotation/overlay compositing
        // (the iOS UIGraphics path) is not yet ported.
        guard let imageData = snapshot.image.pngRepresentation else {
            return nil
        }
        #endif
        return FlutterStandardTypedData(bytes: imageData)
    }

    #if os(iOS)
    private func drawAnnotations(annotation: FlutterAnnotation, point: CGPoint) {
        let annotationView = self.getAnnotationView(annotation: annotation)

        if annotationView is MKMarkerAnnotationView {
            var offsetPoint = point
            offsetPoint.x -= annotationView.bounds.width / 2
            offsetPoint.y -= annotationView.bounds.height / 2
            annotationView.drawHierarchy(
                in: CGRect(x: offsetPoint.x, y: offsetPoint.y, width: annotationView.bounds.width, height: annotationView.bounds.height),
                afterScreenUpdates: true
            )
        } else if let image = annotationView.image {
            // Place the image so its normalized anchor point lands on the
            // annotation's coordinate, matching MKAnnotationView.anchorPoint.
            let origin = CGPoint(
                x: point.x - annotation.anchorPoint.x * image.size.width,
                y: point.y - annotation.anchorPoint.y * image.size.height
            )
            image.draw(at: origin)
        }
    }

    private func drawOverlays(overlay: MKOverlay, snapshot: MKMapSnapshotter.Snapshot, context: UIGraphicsRendererContext) {
        if let flutterOverlay = overlay as? any FlutterOverlay {
            flutterOverlay.getCAShapeLayer(snapshot: snapshot).render(in: context.cgContext)
        }
    }
    #endif
}

#if os(iOS)
extension MapKitViewHost: FlutterPlatformView {
    public func view() -> UIView {
        return contentView
    }
}
#endif
