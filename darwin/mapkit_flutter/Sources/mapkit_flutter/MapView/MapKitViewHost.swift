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
    var flutterApi: MapKitFlutterApi
    private let hostMessenger: ConnectionTrackingMessenger
    var currentlySelectedAnnotation: String?
    var suppressSelectionCallbacksForAnnotationId: String?
    var tileOverlays: [String: FlutterTileOverlay] = [:]
    var annotationsById: [String: FlutterAnnotation] = [:]
    var polylinesById: [String: any FlutterOverlay] = [:]
    var polygonsById: [String: any FlutterOverlay] = [:]
    var circlesById: [String: any FlutterOverlay] = [:]

    public convenience init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64) {
        #if os(iOS)
        self.init(messenger: registrar.messenger(), id: id)
        #elseif os(macOS)
        self.init(messenger: registrar.messenger, id: id)
        #endif
    }

    init(messenger: FlutterBinaryMessenger, id: Int64) {
        let suffix = "\(id)"
        self.hostMessenger = ConnectionTrackingMessenger(messenger)
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
        MapKitHostApiSetup.setUp(binaryMessenger: hostMessenger, api: self, messageChannelSuffix: suffix)
    }

    // MARK: - MapKitHostApi

    func initialize(params: PlatformMapViewCreationParams) throws {
        // Decode the annotations (icons can be invalid) before touching the
        // map, so a throw leaves it untouched.
        let annotations = try params.annotations.map(FlutterAnnotation.init(fromPlatform:))
        try self.mapView.apply(configuration: params.configuration)
        self.mapView.move(.camera(params.initialCamera.mkCamera), animated: false)
        self.annotationsToAdd(annotations)
        self.applyOverlayUpdate(
            into: &self.polylinesById,
            adding: params.polylines.map { makeStyledPolyline(fromPlatform: $0) },
            changing: [],
            removing: [])
        self.applyOverlayUpdate(
            into: &self.polygonsById,
            adding: params.polygons.map(FlutterPolygon.init(fromPlatform:)),
            changing: [],
            removing: [])
        self.applyOverlayUpdate(
            into: &self.circlesById,
            adding: params.circles.map(FlutterCircle.init(fromPlatform:)),
            changing: [],
            removing: [])
    }

    func setCamera(camera: PlatformMapCamera, animated: Bool) throws {
        self.mapView.move(.camera(camera.mkCamera), animated: animated)
    }

    func setRegion(region: PlatformCoordinateRegion, animated: Bool) throws {
        self.mapView.move(.region(region.mkRegion), animated: animated)
    }

    func setCenter(coordinate: PlatformCoordinate, animated: Bool) throws {
        self.mapView.move(.center(coordinate.clCoordinate), animated: animated)
    }

    func getCamera() throws -> PlatformMapCamera? {
        guard self.mapView.hasLayout else { return nil }
        return self.mapView.currentPlatformCamera()
    }

    func getRegion() throws -> PlatformCoordinateRegion? {
        return self.mapView.currentPlatformRegion()
    }

    func convertToPoint(coordinate: PlatformCoordinate) throws -> PlatformPoint? {
        guard self.mapView.hasLayout else { return nil }
        let point = self.mapView.convert(coordinate.clCoordinate, toPointTo: self.mapView)
        return PlatformPoint(x: Double(point.x), y: Double(point.y))
    }

    func convertToCoordinate(point: PlatformPoint) throws -> PlatformCoordinate? {
        guard self.mapView.hasLayout else { return nil }
        let coordinate = self.mapView.convert(
            CGPoint(x: point.x, y: point.y),
            toCoordinateFrom: self.mapView
        )
        return .from(coordinate)
    }

    func updateAnnotations(toAdd: [PlatformAnnotation], toChange: [PlatformAnnotation], idsToRemove: [String]) throws {
        // Decode first: an invalid icon fails the whole update, never half of it.
        let added = try toAdd.map(FlutterAnnotation.init(fromPlatform:))
        let changed = try toChange.map(FlutterAnnotation.init(fromPlatform:))
        if !added.isEmpty { self.annotationsToAdd(added) }
        if !changed.isEmpty { self.annotationsToChange(changed) }
        if !idsToRemove.isEmpty { self.annotationsToRemove(idsToRemove) }
    }

    func updatePolylines(toAdd: [PlatformPolyline], toChange: [PlatformPolyline], idsToRemove: [String]) throws {
        self.applyOverlayUpdate(
            into: &self.polylinesById,
            adding: toAdd.map { makeStyledPolyline(fromPlatform: $0) },
            changing: toChange.map { makeStyledPolyline(fromPlatform: $0) },
            removing: idsToRemove)
    }

    func updatePolygons(toAdd: [PlatformPolygon], toChange: [PlatformPolygon], idsToRemove: [String]) throws {
        self.applyOverlayUpdate(
            into: &self.polygonsById,
            adding: toAdd.map(FlutterPolygon.init(fromPlatform:)),
            changing: toChange.map(FlutterPolygon.init(fromPlatform:)),
            removing: idsToRemove)
    }

    func updateCircles(toAdd: [PlatformCircle], toChange: [PlatformCircle], idsToRemove: [String]) throws {
        self.applyOverlayUpdate(
            into: &self.circlesById,
            adding: toAdd.map(FlutterCircle.init(fromPlatform:)),
            changing: toChange.map(FlutterCircle.init(fromPlatform:)),
            removing: idsToRemove)
    }

    func updateMapConfiguration(configuration: PlatformMapConfiguration) throws {
        try self.mapView.apply(configuration: configuration)
    }

    func selectAnnotation(annotationId: String) throws -> Bool {
        return self.selectAnnotation(with: annotationId)
    }

    func deselectAnnotation(annotationId: String) throws -> Bool {
        return self.deselectAnnotation(with: annotationId)
    }

    func isAnnotationSelected(annotationId: String) throws -> Bool {
        return self.isAnnotationSelected(with: annotationId)
    }

    func takeSnapshot(options: PlatformSnapshotOptions, completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void) {
        Task { @MainActor in
            do {
                guard let data = try await self.takeSnapshot(options: options) else {
                    completion(.failure(mapKitError(.snapshotFailed, "Snapshot produced no image data.")))
                    return
                }
                completion(.success(data))
            } catch let error as MapKitHostError {
                completion(.failure(error))
            } catch {
                completion(.failure(mapKitError(.snapshotFailed, error.localizedDescription)))
            }
        }
    }

    /// `false` only when no scene exists for the coordinate; a failed scene
    /// request or a missing presenter is an error, not "no scene".
    func openLookAround(coordinate: PlatformCoordinate, completion: @escaping (Result<Bool, Error>) -> Void) {
        #if os(iOS)
        let coord = coordinate.clCoordinate
        Task { @MainActor in
            let scene: MKLookAroundScene?
            do {
                scene = try await Self.requestLookAroundScene(at: coord)
            } catch {
                completion(.failure(mapKitError(.lookAroundFailed, error.localizedDescription)))
                return
            }
            guard let scene else {
                completion(.success(false))
                return
            }
            let vc = MKLookAroundViewController(scene: scene)
            guard let host = self.contentView.window?.rootViewController
                ?? UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                    .first else {
                completion(.failure(mapKitError(.lookAroundFailed, "No view controller to present Look Around from.")))
                return
            }
            Self.present(vc, over: host, completion: completion)
        }
        #elseif os(macOS)
        // MKLookAroundViewController exists on macOS 13+, but presenting it from the AppKit host isn't wired yet.
        completion(.failure(mapKitError(.unsupportedPlatform, "openLookAround is iOS only.")))
        #endif
    }

    #if os(iOS)
    /// UIKit drops a presentation it rejects (presenter off-window or mid-transition)
    /// without calling back; an accepted one links `vc` to its presenter synchronously.
    static func present(
        _ vc: UIViewController, over host: UIViewController, completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        var presenter = host
        while let next = presenter.presentedViewController, !next.isBeingDismissed {
            presenter = next
        }
        presenter.present(vc, animated: true) {
            completion(.success(true))
        }
        if vc.presentingViewController == nil {
            completion(.failure(mapKitError(
                .lookAroundFailed, "UIKit rejected presenting Look Around from \(type(of: presenter)).")))
        }
    }

    /// Runs the scene request off the main actor and hands the result back
    /// with `sending`: older SDKs don't mark `MKLookAroundScene` Sendable, so
    /// awaiting `request.scene` directly from `@MainActor` fails to compile
    /// there. Region isolation proves the fresh scene is safe to move.
    private nonisolated static func requestLookAroundScene(
        at coordinate: CLLocationCoordinate2D
    ) async throws -> sending MKLookAroundScene? {
        try await MKLookAroundSceneRequest(coordinate: coordinate).scene
    }
    #endif

    func addTileOverlay(overlay overlayData: PlatformTileOverlay) throws {
        guard tileOverlays[overlayData.id] == nil else {
            throw mapKitError(.duplicateId, "A tile overlay with id \"\(overlayData.id)\" is already on the map.")
        }
        let overlay = FlutterTileOverlay(fromPlatform: overlayData)
        tileOverlays[overlay.id] = overlay
        self.mapView.addOverlay(overlay, level: overlay.overlayLevel)
    }

    func removeTileOverlay(tileOverlayId: String) throws -> Bool {
        guard let overlay = tileOverlays.removeValue(forKey: tileOverlayId) else { return false }
        self.mapView.removeOverlay(overlay)
        return true
    }

    func dispose() throws {
        hostMessenger.removeAllHandlers()
        mapView.tearDown()
        annotationsById.removeAll()
        polylinesById.removeAll()
        polygonsById.removeAll()
        circlesById.removeAll()
        tileOverlays.removeAll()
        currentlySelectedAnnotation = nil
        suppressSelectionCallbacksForAnnotationId = nil
    }

    private func applyOverlayUpdate(
        into store: inout [String: any FlutterOverlay],
        adding: [any FlutterOverlay],
        changing: [any FlutterOverlay],
        removing: [String]
    ) {
        var overlaysToRemove: [MKOverlay] = []
        for id in removing {
            if let overlay = store.removeValue(forKey: id) {
                overlaysToRemove.append(overlay)
            }
        }
        for new in changing {
            if let old = store.removeValue(forKey: new.id) {
                overlaysToRemove.append(old)
            }
        }
        for new in adding {
            if let old = store.removeValue(forKey: new.id) {
                overlaysToRemove.append(old)
            }
        }

        if !overlaysToRemove.isEmpty {
            self.mapView.removeOverlays(overlaysToRemove)
        }

        for new in changing {
            store[new.id] = new
            self.mapView.addFlutterOverlay(new)
        }
        for new in adding {
            store[new.id] = new
            self.mapView.addFlutterOverlay(new)
        }
    }
}

extension MapKitViewHost: MKMapViewDelegate {
    // onIdle
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if self.mapView.bounds.size != .zero {
            let camera = self.mapView.currentPlatformCamera()
            self.flutterApi.send { try await $0.onCameraMove(camera: camera) }
        }
        self.flutterApi.send { try await $0.onCameraIdle() }
    }

    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        guard self.mapView.bounds.size != .zero else { return }
        let camera = self.mapView.currentPlatformCamera()
        flutterApi.send { try await $0.onCameraMove(camera: camera) }
    }

    // onMoveStarted
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.flutterApi.send { try await $0.onCameraMoveStarted() }
    }

    public func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        let platformMode = PlatformUserTrackingMode(mkMode: mode)
        self.flutterApi.send { try await $0.onUserTrackingModeChanged(mode: platformMode) }
    }

    public func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        let message = error.localizedDescription
        self.flutterApi.send { try await $0.onDidFailLoadingMap(error: message) }
    }

    public func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        let message = error.localizedDescription
        self.flutterApi.send { try await $0.onDidFailToLocateUser(error: message) }
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
    /// Everything a snapshot needs from the live map, as Sendable values: the
    /// snapshotter runs off the main actor and must never see `mapView` objects.
    struct SnapshotInput: Sendable {
        var region: MKCoordinateRegion
        var size: CGSize
        var displayScale: CGFloat
        var camera: PlatformMapCamera
        var configuration: PlatformMapConfiguration?
        var isDark: Bool
        var options: PlatformSnapshotOptions
    }

    func snapshotInput(_ options: PlatformSnapshotOptions) -> SnapshotInput {
        #if os(iOS)
        // Unspecified traits report displayScale == 0, which leaves the scale to MapKit.
        let displayScale = self.mapView.traitCollection.displayScale
        let isDark = self.mapView.traitCollection.userInterfaceStyle == .dark
        #elseif os(macOS)
        let displayScale: CGFloat = 0
        let isDark = self.mapView.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        #endif
        return SnapshotInput(
            region: self.mapView.region,
            size: self.mapView.frame.size,
            displayScale: displayScale,
            camera: self.mapView.currentPlatformCamera(),
            configuration: self.mapView.appliedConfiguration,
            isDark: isDark,
            options: options)
    }

    nonisolated static func makeSnapshotOptions(_ input: SnapshotInput) throws -> MKMapSnapshotter.Options {
        let options = MKMapSnapshotter.Options()
        options.region = input.region
        options.size = input.size
        options.camera = input.camera.mkCamera
        if let configuration = input.configuration {
            options.preferredConfiguration = try FlutterMapView.makeMapConfiguration(
                configuration, hidingPointsOfInterest: !input.options.showsPointsOfInterest)
        }
        #if os(iOS)
        // Not `UITraitCollection { }`: its `UIMutableTraits` closure is UI-actor isolated (27 SDK).
        let traits = UITraitCollection(userInterfaceStyle: input.isDark ? .dark : .light)
        options.traitCollection = input.displayScale > 0
            ? traits.replacing(UITraitDisplayScale.self, value: input.displayScale)
            : traits
        #elseif os(macOS)
        options.appearance = NSAppearance(named: input.isDark ? .darkAqua : .aqua)
        #endif
        return options
    }

    private func takeSnapshot(options: PlatformSnapshotOptions) async throws -> FlutterStandardTypedData? {
        let input = snapshotInput(options)
        guard input.size.width > 0, input.size.height > 0 else {
            throw mapKitError(.snapshotFailed, "Map view has zero size.")
        }
        // Caller-side options exist only for `size`/`mapRect` in the
        // compositing pass below; the snapshotter gets its own copy off-actor.
        let snapshotOptions = try Self.makeSnapshotOptions(input)

        let snapshot = try await Self.startSnapshot(input)

        #if os(iOS)
        let image = UIGraphicsImageRenderer(size: snapshotOptions.size).image { context in
            snapshot.image.draw(at: .zero)
            let rect = snapshotOptions.mapRect
            // Image-space bounds: `snapshot.point(for:)` projects into this
            // space, so drawn frames are tested here rather than in map space.
            let bounds = CGRect(origin: .zero, size: snapshotOptions.size)
            if options.showsOverlays {
                self.drawOverlays(snapshot: snapshot, mapRect: rect, in: context.cgContext)
            }
            if options.showsAnnotations {
                for annotation in self.mapView.getMapViewAnnotations() where !annotation.isHidden {
                    self.drawAnnotations(annotation: annotation, point: snapshot.point(for: annotation.coordinate), bounds: bounds)
                }
            }
        }
        guard let imageData = image.pngRepresentation else {
            return nil
        }
        #elseif os(macOS)
        guard let imageData = self.composite(snapshot, options: options, snapshotOptions: snapshotOptions) else {
            return nil
        }
        #endif
        return FlutterStandardTypedData(bytes: imageData)
    }

    #if os(macOS)
    /// Draws annotations and overlays over the snapshot at its pixel size.
    /// Annotations draw in a top-left-origin point space like the iOS
    /// renderer; macOS `snapshot.point(for:)` is bottom-left-origin, so their
    /// points are flipped and the overlay layers render under a local re-flip.
    private func composite(
        _ snapshot: MKMapSnapshotter.Snapshot,
        options: PlatformSnapshotOptions,
        snapshotOptions: MKMapSnapshotter.Options
    ) -> Data? {
        let size = snapshotOptions.size
        guard let base = snapshot.image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: base.width, height: base.height, bitsPerComponent: 8, bytesPerRow: 0,
                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else {
            return nil
        }
        context.draw(base, in: CGRect(x: 0, y: 0, width: base.width, height: base.height))
        let scale = CGFloat(base.width) / size.width
        context.translateBy(x: 0, y: CGFloat(base.height))
        context.scaleBy(x: scale, y: -scale)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        let bounds = CGRect(origin: .zero, size: size)
        if options.showsOverlays {
            context.saveGState()
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
            self.drawOverlays(snapshot: snapshot, mapRect: snapshotOptions.mapRect, in: context)
            context.restoreGState()
        }
        if options.showsAnnotations {
            for annotation in self.mapView.getMapViewAnnotations() where !annotation.isHidden {
                let point = snapshot.point(for: annotation.coordinate)
                self.drawAnnotations(annotation: annotation, point: CGPoint(x: point.x, y: size.height - point.y), bounds: bounds)
            }
        }
        NSGraphicsContext.restoreGraphicsState()

        guard let composed = context.makeImage() else {
            return nil
        }
        let rep = NSBitmapImageRep(cgImage: composed)
        rep.size = size
        return rep.representation(using: .png, properties: [:])
    }
    #endif

    /// Runs the snapshotter off the main actor and hands the result back with
    /// `sending`: older SDKs don't mark `MKMapSnapshotter.Snapshot` Sendable,
    /// so awaiting `start()` directly from `@MainActor` fails to compile
    /// there. Only the Sendable input crosses in; the options and snapshotter
    /// live entirely in this disconnected region, so the fresh snapshot is
    /// provably safe to move out.
    private nonisolated static func startSnapshot(_ input: SnapshotInput) async throws -> sending MKMapSnapshotter.Snapshot {
        try await MKMapSnapshotter(options: try makeSnapshotOptions(input)).start()
    }

    /// Skips fully off-image annotations (their drawn frame does not
    /// intersect `bounds`) before the expensive hierarchy / image draw;
    /// partially visible edge annotations still draw, matching MKMapView.
    private func drawAnnotations(annotation: FlutterAnnotation, point: CGPoint, bounds: CGRect) {
        let annotationView = self.getAnnotationView(annotation: annotation)

        if annotationView is MKMarkerAnnotationView {
            let frame = CGRect(
                x: point.x - annotationView.bounds.width / 2,
                y: point.y - annotationView.bounds.height / 2,
                width: annotationView.bounds.width,
                height: annotationView.bounds.height
            )
            guard frame.intersects(bounds) else { return }
            #if os(iOS)
            annotationView.drawHierarchy(in: frame, afterScreenUpdates: true)
            #elseif os(macOS)
            // Off-window marker views build their balloon only when prepared.
            annotationView.prepareForDisplay()
            annotationView.layoutSubtreeIfNeeded()
            guard let rep = annotationView.bitmapImageRepForCachingDisplay(in: annotationView.bounds) else { return }
            annotationView.cacheDisplay(in: annotationView.bounds, to: rep)
            rep.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            #endif
        } else if let image = annotationView.image {
            // Place the image so its normalized anchor point lands on the
            // annotation's coordinate, matching MKAnnotationView.anchorPoint.
            let origin = CGPoint(
                x: point.x - annotation.anchorPoint.x * image.size.width,
                y: point.y - annotation.anchorPoint.y * image.size.height
            )
            guard CGRect(origin: origin, size: image.size).intersects(bounds) else { return }
            #if os(iOS)
            image.draw(at: origin, blendMode: .normal, alpha: CGFloat(annotation.alpha))
            #elseif os(macOS)
            image.draw(
                in: CGRect(origin: origin, size: image.size), from: .zero, operation: .sourceOver,
                fraction: CGFloat(annotation.alpha), respectFlipped: true, hints: nil)
            #endif
        }
    }

    private func drawOverlays(snapshot: MKMapSnapshotter.Snapshot, mapRect: MKMapRect, in context: CGContext) {
        for overlay in self.mapView.overlays where overlay.intersects?(mapRect) ?? overlay.boundingMapRect.intersects(mapRect) {
            if let flutterOverlay = overlay as? any FlutterOverlay {
                flutterOverlay.drawSnapshot(snapshot, in: context)
            }
        }
    }
}

#if os(iOS)
// `@preconcurrency`: FlutterPlatformView is nonisolated; the engine calls
// `view()` on the platform thread (main), same as the MapKitHostApi
// conformance above.
extension MapKitViewHost: @preconcurrency FlutterPlatformView {
    public func view() -> UIView {
        return contentView
    }
}
#endif
