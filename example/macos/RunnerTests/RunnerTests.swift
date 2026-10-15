import Cocoa
import FlutterMacOS
import MapKit
import XCTest
@testable import mapkit_flutter

/// Records every host -> Dart message and answers with pigeon's success envelope.
final class RecordingMessenger: NSObject, FlutterBinaryMessenger {
    private(set) var sent: [(channel: String, args: [Any?])] = []
    private var pending: [(method: String, expectation: XCTestExpectation)] = []

    func send(onChannel channel: String, message: Data?) {
        record(channel, message)
    }

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
        record(channel, message)
        callback?(MessagesPigeonCodec.shared.encode([] as [Any?]))
    }

    func setMessageHandlerOnChannel(
        _ channel: String,
        binaryMessageHandler handler: FlutterBinaryMessageHandler?
    ) -> FlutterBinaryMessengerConnection {
        0
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}

    func args(of method: String) -> [[Any?]] {
        sent.filter { $0.channel.contains(".\(method).") }.map(\.args)
    }

    func expectation(for method: String, in test: XCTestCase) -> XCTestExpectation {
        let expectation = test.expectation(description: method)
        expectation.assertForOverFulfill = false
        pending.append((method, expectation))
        return expectation
    }

    private func record(_ channel: String, _ message: Data?) {
        let args = MessagesPigeonCodec.shared.decode(message) as? [Any?] ?? []
        sent.append((channel, args))
        for entry in pending where channel.contains(".\(entry.method).") {
            entry.expectation.fulfill()
        }
    }
}

/// Hands out a fresh connection per handler and tracks which are still registered.
final class ConnectionCountingMessenger: NSObject, FlutterBinaryMessenger {
    private(set) var live: Set<FlutterBinaryMessengerConnection> = []
    private var next: FlutterBinaryMessengerConnection = 0

    func send(onChannel channel: String, message: Data?) {}

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {}

    func setMessageHandlerOnChannel(
        _ channel: String,
        binaryMessageHandler handler: FlutterBinaryMessageHandler?
    ) -> FlutterBinaryMessengerConnection {
        next += 1
        live.insert(next)
        return next
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
        live.remove(connection)
    }
}

private func annotation(_ id: String, title: String? = nil, callout: Bool = false) -> PlatformAnnotation {
    PlatformAnnotation(
        id: id,
        coordinate: PlatformCoordinate(latitude: 1, longitude: 2),
        icon: PlatformAnnotationIcon(type: .marker),
        title: title,
        calloutConsumesTapEvents: callout,
        alpha: 1,
        anchorPointX: 0.5,
        anchorPointY: 1,
        isDraggable: true,
        isHidden: false,
        zPriority: 500
    )
}

/// A real PNG (MapKit must decode it), `width`×`height` points at ratio 1.
private func pngIcon(width: CGFloat = 20, height: CGFloat = 40) -> PlatformAnnotationIcon {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    NSColor.red.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    image.unlockFocus()
    let png = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
    return PlatformAnnotationIcon(type: .image, imageBytes: FlutterStandardTypedData(bytes: png), imagePixelRatio: 1)
}

private func configuration(
    scale: Bool = false,
    tracking: PlatformUserTrackingMode = .none,
    kind: PlatformMapKind = .standard,
    trackingButton: Bool = false,
    userLocation: Bool = false
) -> PlatformMapConfiguration {
    PlatformMapConfiguration(
        kind: kind,
        emphasisStyle: .standard,
        elevationStyle: .flat,
        showsTraffic: false,
        showsCompass: true,
        showsScale: scale,
        showsUserLocation: userLocation,
        showsUserTrackingButton: trackingButton,
        userTrackingMode: tracking,
        insetsLayoutMarginsFromSafeArea: true,
        isRotateEnabled: true,
        isScrollEnabled: true,
        isZoomEnabled: true,
        isPitchEnabled: true,
        selectableMapFeatures: []
    )
}

private func circle(
    _ id: String, zIndex: Int64 = 0, hidden: Bool = false, level: PlatformOverlayLevel = .aboveRoads
) -> PlatformCircle {
    PlatformCircle(
        id: id,
        center: PlatformCoordinate(latitude: 0, longitude: 0),
        radius: 50_000,
        fillColorArgb: 0xFF00_00FF,
        strokeColorArgb: 0xFF00_00FF,
        lineWidth: 1,
        zIndex: zIndex,
        isHidden: hidden,
        consumeTapEvents: true,
        level: level
    )
}

@MainActor
final class RunnerTests: XCTestCase {
    func testDisposeRemovesEveryHandler() throws {
        let messenger = ConnectionCountingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        host.mapView.showsUserLocation = true
        XCTAssertFalse(messenger.live.isEmpty)

        try host.dispose()

        XCTAssertEqual(messenger.live, [])
        XCTAssertNil(host.mapView.delegate)
        XCTAssertFalse(host.mapView.showsUserLocation)
    }

    func testGeodesicPolylineIsSafeToStyle() {
        let polyline = makeStyledPolyline(fromPlatform: PlatformPolyline(
            id: "arc",
            coordinates: [
                PlatformCoordinate(latitude: 40.6, longitude: -73.8),
                PlatformCoordinate(latitude: 51.5, longitude: -0.1),
            ],
            strokeColorArgb: 0xFF00_00FF,
            lineWidth: 2,
            lineCap: .round,
            lineJoin: .round,
            isHidden: false,
            consumeTapEvents: false,
            isGeodesic: true,
            level: .aboveRoads,
            zIndex: 0,
            lineDashPattern: [6, 3]
        ))

        XCTAssertEqual(polyline.dashPattern, [6, 3])
        XCTAssertGreaterThan(polyline.pointCount, 2)
    }

    func testPolygonSnapshotOutlineIsOneClosedRing() {
        let polygon = FlutterPolygon(fromPlatform: PlatformPolygon(
            id: "triangle",
            coordinates: [
                PlatformCoordinate(latitude: 0, longitude: 0),
                PlatformCoordinate(latitude: 1, longitude: 0),
                PlatformCoordinate(latitude: 0, longitude: 1),
            ],
            interiorPolygons: [],
            fillColorArgb: 0xFF00_00FF,
            strokeColorArgb: 0xFF00_00FF,
            lineWidth: 1,
            zIndex: 0,
            isHidden: false,
            consumeTapEvents: false,
            level: .aboveRoads
        ))
        var elements: [String] = []

        polygon.outlinePath { CGPoint(x: $0.longitude, y: $0.latitude) }.applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint: elements.append("M\(e.points[0].x),\(e.points[0].y)")
            case .addLineToPoint: elements.append("L\(e.points[0].x),\(e.points[0].y)")
            case .closeSubpath: elements.append("Z")
            default: elements.append("?")
            }
        }

        XCTAssertEqual(elements, ["M0.0,0.0", "L0.0,1.0", "L1.0,0.0", "Z"])
    }

    func testCalloutToggleReachesNative() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        try host.updateAnnotations(toAdd: [annotation("a")], toChange: [], idsToRemove: [])

        try host.updateAnnotations(toAdd: [], toChange: [annotation("a", callout: true)], idsToRemove: [])

        XCTAssertEqual(host.annotationsById["a"]?.calloutConsumesTapEvents, true)
    }

    func testFirstUpdateAfterDragApplies() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        try host.updateAnnotations(toAdd: [annotation("a", title: "A")], toChange: [], idsToRemove: [])
        let view = MKAnnotationView(annotation: host.annotationsById["a"], reuseIdentifier: nil)
        host.mapView(host.mapView, annotationView: view, didChange: .ending, fromOldState: .dragging)

        try host.updateAnnotations(toAdd: [], toChange: [annotation("a", title: "B")], idsToRemove: [])

        XCTAssertEqual(host.annotationsById["a"]?.title, "B")
    }

    func testCalloutOffsetIgnoresViewPosition() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let flutterAnnotation = try FlutterAnnotation(fromPlatform: annotation("a"))
        let view = MKAnnotationView(annotation: flutterAnnotation, reuseIdentifier: nil)
        view.frame = CGRect(x: 300, y: 120, width: 40, height: 40)

        host.initInfoWindow(annotation: flutterAnnotation, annotationView: view)

        XCTAssertEqual(view.calloutOffset, .zero)
    }

    func testHiddenOverlayDoesNotConsumeTap() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        try host.updateCircles(toAdd: [circle("hidden", hidden: true)], toChange: [], idsToRemove: [])
        let mapTap = messenger.expectation(for: "onMapTap", in: self)

        TouchHandler.handleMapTap(
            at: CLLocationCoordinate2D(latitude: 0, longitude: 0), flutterApi: host.flutterApi, in: host.mapView)

        await fulfillment(of: [mapTap], timeout: 2)
        XCTAssertTrue(messenger.args(of: "onCircleTap").isEmpty)
    }

    func testOnlyTopMostOverlayReceivesTap() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        try host.updateCircles(
            toAdd: [circle("high", zIndex: 1), circle("low", zIndex: 0)], toChange: [], idsToRemove: [])
        let circleTap = messenger.expectation(for: "onCircleTap", in: self)

        TouchHandler.handleMapTap(
            at: CLLocationCoordinate2D(latitude: 0, longitude: 0), flutterApi: host.flutterApi, in: host.mapView)

        await fulfillment(of: [circleTap], timeout: 2)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(messenger.args(of: "onCircleTap").map { $0.compactMap { $0 as? String } }, [["high"]])
    }

    func testTrackingModeReappliedOnlyWhenItChanges() throws {
        let view = CountingMapView()

        try view.apply(configuration: configuration(tracking: .follow))
        try view.apply(configuration: configuration(scale: true, tracking: .follow))
        XCTAssertEqual(view.trackingModeSets, 1)

        try view.apply(configuration: configuration(scale: true, tracking: .none))
        XCTAssertEqual(view.trackingModeSets, 2)
    }

    func testLabelsLevelOverlayTakesTapBeforeRoadsLevel() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        try host.updateCircles(
            toAdd: [circle("roads", zIndex: 5, level: .aboveRoads), circle("labels", zIndex: 0, level: .aboveLabels)],
            toChange: [], idsToRemove: [])
        let circleTap = messenger.expectation(for: "onCircleTap", in: self)

        TouchHandler.handleMapTap(
            at: CLLocationCoordinate2D(latitude: 0, longitude: 0), flutterApi: host.flutterApi, in: host.mapView)

        await fulfillment(of: [circleTap], timeout: 2)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(messenger.args(of: "onCircleTap").map { $0.compactMap { $0 as? String } }, [["labels"]])
    }

    func testSnapshotInputCarriesMapConfigurationAndAppearance() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        host.mapView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        try host.mapView.apply(configuration: configuration(kind: .imagery))
        host.mapView.appearance = NSAppearance(named: .darkAqua)

        let input = host.snapshotInput(PlatformSnapshotOptions(
            showsPointsOfInterest: true, showsAnnotations: false, showsOverlays: false))
        let options = try MapKitViewHost.makeSnapshotOptions(input)

        XCTAssertTrue(options.preferredConfiguration is MKImageryMapConfiguration)
        XCTAssertEqual(options.appearance?.name, .darkAqua)
    }

    func testAddingATileOverlayIdTwiceThrowsAndKeepsTheFirst() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let tiles = PlatformTileOverlay(
            id: "osm",
            urlTemplate: "https://tile.example.com/{z}/{x}/{y}.png",
            minimumZ: 0,
            maximumZ: 19,
            tileSize: 256,
            canReplaceMapContent: false,
            alpha: 1,
            level: .aboveRoads
        )

        try host.addTileOverlay(overlay: tiles)
        XCTAssertThrowsError(try host.addTileOverlay(overlay: tiles)) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "duplicate-id")
        }

        XCTAssertEqual(host.mapView.overlays.count, 1)
        XCTAssertTrue(try host.removeTileOverlay(tileOverlayId: "osm"))
        XCTAssertFalse(try host.removeTileOverlay(tileOverlayId: "osm"))
        XCTAssertEqual(host.mapView.overlays.count, 0)
    }

    func testTrackingButtonAppliesOnMacOS() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)

        try host.mapView.apply(configuration: configuration(trackingButton: true))

        XCTAssertTrue(host.mapView.showsUserTrackingButton)
    }

    func testSnapshotOptionsFollowMapStyleCameraAndAppearance() throws {
        let input = MapKitViewHost.SnapshotInput(
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.0),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)),
            size: CGSize(width: 200, height: 200),
            displayScale: 0,
            camera: PlatformMapCamera(
                centerCoordinate: PlatformCoordinate(latitude: 37.33, longitude: -122.0),
                distance: 2000,
                heading: 90,
                pitch: 30),
            configuration: configuration(kind: .imagery),
            isDark: true,
            options: PlatformSnapshotOptions(
                showsPointsOfInterest: true, showsAnnotations: false, showsOverlays: false))

        let options = try MapKitViewHost.makeSnapshotOptions(input)

        XCTAssertTrue(options.preferredConfiguration is MKImageryMapConfiguration)
        XCTAssertEqual(options.camera.heading, 90, accuracy: 0.001)
        XCTAssertEqual(options.appearance?.name, .darkAqua)
    }

    func testSelectAndDeselectReachDart() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        try host.updateAnnotations(toAdd: [annotation("a")], toChange: [], idsToRemove: [])
        let view = MKMarkerAnnotationView(annotation: host.annotationsById["a"], reuseIdentifier: nil)
        let selected = messenger.expectation(for: "onAnnotationSelect", in: self)
        let deselected = messenger.expectation(for: "onAnnotationDeselect", in: self)

        host.mapView(host.mapView, didSelect: view)
        host.mapView(host.mapView, didDeselect: view)

        await fulfillment(of: [selected, deselected], timeout: 2, enforceOrder: true)
        XCTAssertNil(host.currentlySelectedAnnotation)
    }

    func testVisibleRegionChangeStreamsCamera() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        host.mapView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        try await Task.sleep(for: .milliseconds(200))
        let before = messenger.args(of: "onCameraMove").count
        let moved = messenger.expectation(for: "onCameraMove", in: self)

        (host as MKMapViewDelegate).mapViewDidChangeVisibleRegion?(host.mapView)

        await fulfillment(of: [moved], timeout: 2)
        XCTAssertEqual(messenger.args(of: "onCameraMove").count, before + 1)
    }

    func testCrossTypeOverlaysShareIdIndependently() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let poly = PlatformPolyline(
            id: "zone",
            coordinates: [
                PlatformCoordinate(latitude: 0, longitude: 0),
                PlatformCoordinate(latitude: 1, longitude: 1),
            ],
            strokeColorArgb: 0xFF00_00FF,
            lineWidth: 2,
            lineCap: .round,
            lineJoin: .round,
            isHidden: false,
            consumeTapEvents: false,
            isGeodesic: false,
            level: .aboveRoads,
            zIndex: 0
        )
        let gon = PlatformPolygon(
            id: "zone",
            coordinates: [
                PlatformCoordinate(latitude: 0, longitude: 0),
                PlatformCoordinate(latitude: 1, longitude: 0),
                PlatformCoordinate(latitude: 0, longitude: 1),
            ],
            interiorPolygons: [],
            fillColorArgb: 0xFF00_00FF,
            strokeColorArgb: 0xFF00_00FF,
            lineWidth: 1,
            zIndex: 0,
            isHidden: false,
            consumeTapEvents: false,
            level: .aboveRoads
        )

        try host.updatePolylines(toAdd: [poly], toChange: [], idsToRemove: [])
        try host.updatePolygons(toAdd: [gon], toChange: [], idsToRemove: [])
        try host.updateCircles(toAdd: [circle("zone")], toChange: [], idsToRemove: [])
        XCTAssertEqual(host.mapView.overlays.count, 3)

        try host.updatePolylines(toAdd: [], toChange: [], idsToRemove: ["zone"])
        XCTAssertEqual(host.mapView.overlays.count, 2)
        XCTAssertNil(host.polylinesById["zone"])
        XCTAssertNotNil(host.polygonsById["zone"])
        XCTAssertNotNil(host.circlesById["zone"])
    }

    func testPolygonOutlineIncludesInteriorHoleAndEvenOddFillRule() {
        let polygon = FlutterPolygon(fromPlatform: PlatformPolygon(
            id: "donut",
            coordinates: [
                PlatformCoordinate(latitude: 0, longitude: 0),
                PlatformCoordinate(latitude: 4, longitude: 0),
                PlatformCoordinate(latitude: 0, longitude: 4),
            ],
            interiorPolygons: [
                [
                    PlatformCoordinate(latitude: 1, longitude: 1),
                    PlatformCoordinate(latitude: 2, longitude: 1),
                    PlatformCoordinate(latitude: 1, longitude: 2),
                ],
            ],
            fillColorArgb: 0xFF00_00FF,
            strokeColorArgb: 0xFF00_00FF,
            lineWidth: 1,
            zIndex: 0,
            isHidden: false,
            consumeTapEvents: false,
            level: .aboveRoads
        ))
        var elements: [String] = []
        polygon.outlinePath { CGPoint(x: $0.longitude, y: $0.latitude) }.applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint: elements.append("M\(e.points[0].x),\(e.points[0].y)")
            case .addLineToPoint: elements.append("L\(e.points[0].x),\(e.points[0].y)")
            case .closeSubpath: elements.append("Z")
            default: elements.append("?")
            }
        }

        XCTAssertEqual(
            elements,
            ["M0.0,0.0", "L0.0,4.0", "L4.0,0.0", "Z", "M1.0,1.0", "L1.0,2.0", "L2.0,1.0", "Z"]
        )
    }

    func testSelectionReportsWhetherItTook() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        var hidden = annotation("hidden")
        hidden = PlatformAnnotation(
            id: hidden.id,
            coordinate: hidden.coordinate,
            icon: hidden.icon,
            calloutConsumesTapEvents: false,
            alpha: 1,
            anchorPointX: 0.5,
            anchorPointY: 1,
            isDraggable: false,
            isHidden: true,
            zPriority: 500
        )
        try host.updateAnnotations(
            toAdd: [hidden, annotation("unattached"), annotation("visible")], toChange: [], idsToRemove: [])

        XCTAssertFalse(try host.selectAnnotation(annotationId: "hidden"))
        XCTAssertNil(host.currentlySelectedAnnotation)
        XCTAssertFalse(try host.selectAnnotation(annotationId: "missing"))

        if let unattached = host.annotationsById["unattached"] {
            host.mapView.removeAnnotation(unattached)
        }
        XCTAssertFalse(try host.selectAnnotation(annotationId: "unattached"))

        XCTAssertTrue(try host.selectAnnotation(annotationId: "visible"))
        XCTAssertTrue(try host.isAnnotationSelected(annotationId: "visible"))
        XCTAssertTrue(try host.deselectAnnotation(annotationId: "visible"))
        XCTAssertFalse(try host.isAnnotationSelected(annotationId: "visible"))
        XCTAssertFalse(try host.deselectAnnotation(annotationId: "missing"))
    }

    func testIconTypeSwapWhileSelectedSuppressesSelectionCallbacks() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        try host.updateAnnotations(toAdd: [annotation("a", title: "Pin")], toChange: [], idsToRemove: [])
        let initialView = MKMarkerAnnotationView(annotation: host.annotationsById["a"], reuseIdentifier: nil)
        let initialSelected = messenger.expectation(for: "onAnnotationSelect", in: self)
        host.mapView(host.mapView, didSelect: initialView)
        await fulfillment(of: [initialSelected], timeout: 2)

        let selectCountBefore = messenger.args(of: "onAnnotationSelect").count
        let deselectCountBefore = messenger.args(of: "onAnnotationDeselect").count

        let customIcon = PlatformAnnotation(
            id: "a",
            coordinate: PlatformCoordinate(latitude: 1, longitude: 2),
            icon: pngIcon(),
            title: "Pin",
            calloutConsumesTapEvents: false,
            alpha: 1,
            anchorPointX: 0.5,
            anchorPointY: 1,
            isDraggable: true,
            isHidden: false,
            zPriority: 500
        )
        try host.updateAnnotations(toAdd: [], toChange: [customIcon], idsToRemove: [])
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(messenger.args(of: "onAnnotationSelect").count, selectCountBefore)
        XCTAssertEqual(messenger.args(of: "onAnnotationDeselect").count, deselectCountBefore)
        XCTAssertNil(host.suppressSelectionCallbacksForAnnotationId)
    }

    func testIconTypeSwapToHiddenSendsDeselect() async throws {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        try host.updateAnnotations(toAdd: [annotation("a", title: "Pin")], toChange: [], idsToRemove: [])
        let initialView = MKMarkerAnnotationView(annotation: host.annotationsById["a"], reuseIdentifier: nil)
        let initialSelected = messenger.expectation(for: "onAnnotationSelect", in: self)
        host.mapView(host.mapView, didSelect: initialView)
        await fulfillment(of: [initialSelected], timeout: 2)

        let deselected = messenger.expectation(for: "onAnnotationDeselect", in: self)
        let hiddenCustomIcon = PlatformAnnotation(
            id: "a",
            coordinate: PlatformCoordinate(latitude: 1, longitude: 2),
            icon: pngIcon(),
            title: "Pin",
            calloutConsumesTapEvents: false,
            alpha: 1,
            anchorPointX: 0.5,
            anchorPointY: 1,
            isDraggable: true,
            isHidden: true,
            zPriority: 500
        )
        try host.updateAnnotations(toAdd: [], toChange: [hiddenCustomIcon], idsToRemove: [])
        await fulfillment(of: [deselected], timeout: 2)

        XCTAssertEqual(messenger.args(of: "onAnnotationDeselect").count, 1)
        XCTAssertNil(host.currentlySelectedAnnotation)
    }

    func testTakeSnapshotRejectsZeroSizedMapView() {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        host.mapView.frame = .zero
        let exp = expectation(description: "snapshot fails on zero size")

        host.takeSnapshot(
            options: PlatformSnapshotOptions(
                showsPointsOfInterest: true,
                showsAnnotations: true,
                showsOverlays: true
            )
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure for zero-sized map view")
            case .failure(let error as MapKitHostError):
                XCTAssertEqual(error.code, "snapshot-failed")
            case .failure(let error):
                XCTFail("Unexpected error type: \(error)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
    }
}

@MainActor
final class NaturalApiTests: XCTestCase {
    func testShowsUserLocationAppliesWithoutPrompting() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        try host.mapView.apply(configuration: configuration(userLocation: true))
        XCTAssertTrue(host.mapView.showsUserLocation)
        try host.mapView.apply(configuration: configuration(userLocation: false))
        XCTAssertFalse(host.mapView.showsUserLocation)
    }

    private func polylineHost(lineWidth: Double) throws -> (MapKitViewHost, RecordingMessenger) {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        host.mapView.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        host.mapView.setRegion(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)), animated: false)
        let line = PlatformPolyline(
            id: "line",
            coordinates: [PlatformCoordinate(latitude: 0, longitude: -0.4), PlatformCoordinate(latitude: 0, longitude: 0.4)],
            strokeColorArgb: 0xFF00_00FF, lineWidth: lineWidth, lineCap: .round, lineJoin: .round, isHidden: false,
            consumeTapEvents: true, isGeodesic: false, level: .aboveRoads, zIndex: 0)
        try host.updatePolylines(toAdd: [line], toChange: [], idsToRemove: [])
        return (host, messenger)
    }

    private func tap(_ host: MapKitViewHost, pointsBelowLine offset: CGFloat) -> CLLocationCoordinate2D {
        let center = host.mapView.convert(CLLocationCoordinate2D(latitude: 0, longitude: 0), toPointTo: host.mapView)
        return host.mapView.convert(CGPoint(x: center.x, y: center.y + offset), toCoordinateFrom: host.mapView)
    }

    func testWidePolylineTakesTapsAcrossItsVisibleStroke() async throws {
        let (host, messenger) = try polylineHost(lineWidth: 40)
        let polylineTap = messenger.expectation(for: "onPolylineTap", in: self)
        TouchHandler.handleMapTap(at: tap(host, pointsBelowLine: 15), flutterApi: host.flutterApi, in: host.mapView)
        await fulfillment(of: [polylineTap], timeout: 2)
        XCTAssertTrue(messenger.args(of: "onMapTap").isEmpty)
    }

    func testThinPolylineKeepsTheEightPointMinimum() async throws {
        let (host, messenger) = try polylineHost(lineWidth: 2)
        let mapTap = messenger.expectation(for: "onMapTap", in: self)
        TouchHandler.handleMapTap(at: tap(host, pointsBelowLine: 15), flutterApi: host.flutterApi, in: host.mapView)
        await fulfillment(of: [mapTap], timeout: 2)
        XCTAssertTrue(messenger.args(of: "onPolylineTap").isEmpty)
        let polylineTap = messenger.expectation(for: "onPolylineTap", in: self)
        TouchHandler.handleMapTap(at: tap(host, pointsBelowLine: 6), flutterApi: host.flutterApi, in: host.mapView)
        await fulfillment(of: [polylineTap], timeout: 2)
    }

    func testUndecodableImageBytesFailTheWholeUpdate() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let broken = PlatformAnnotation(
            id: "broken", coordinate: PlatformCoordinate(latitude: 0, longitude: 0),
            icon: PlatformAnnotationIcon(type: .image, imageBytes: FlutterStandardTypedData(bytes: Data([1, 2, 3]))),
            calloutConsumesTapEvents: false, alpha: 1, anchorPointX: 0.5, anchorPointY: 1,
            isDraggable: false, isHidden: false, zPriority: 500)
        XCTAssertThrowsError(
            try host.updateAnnotations(toAdd: [annotation("ok"), broken], toChange: [], idsToRemove: [])
        ) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "invalid-icon")
        }
        XCTAssertTrue(host.annotationsById.isEmpty)
        XCTAssertTrue(host.mapView.annotations.isEmpty)
    }

    func testUnknownSymbolFailsInsteadOfDrawingAPlainMarker() {
        XCTAssertThrowsError(try AnnotationIcon(fromPlatform: PlatformAnnotationIcon(
            type: .marker, glyphSystemImage: "no.such.symbol.xyz"))
        ) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "invalid-icon")
        }
        XCTAssertNoThrow(try AnnotationIcon(fromPlatform: PlatformAnnotationIcon(
            type: .marker, glyphSystemImage: "cup.and.saucer.fill")))
    }

    func testOpenLookAroundIsUnsupportedOnMacOS() {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let done = expectation(description: "look around")
        host.openLookAround(coordinate: PlatformCoordinate(latitude: 0, longitude: 0)) { result in
            switch result {
            case .success(let value): XCTFail("expected unsupported-platform, got \(value)")
            case .failure(let error): XCTAssertEqual((error as? MapKitHostError)?.code, "unsupported-platform")
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
    }

    func testRejectedZoomRangeThrowsAndLeavesTheMapUnchanged() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        try host.mapView.apply(configuration: configuration(scale: false))
        var invalid = configuration(scale: true)
        invalid.cameraZoomRange = PlatformCameraZoomRange(minCenterCoordinateDistance: 10, maxCenterCoordinateDistance: 5)
        XCTAssertThrowsError(try host.mapView.apply(configuration: invalid)) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "invalid-argument")
        }
        XCTAssertFalse(host.mapView.showsScale)
    }

    func testRejectedCameraBoundaryThrows() {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let before = host.mapView.cameraBoundary
        var invalid = configuration()
        invalid.cameraBoundary = PlatformCoordinateRegion(
            center: PlatformCoordinate(latitude: .nan, longitude: 0),
            span: PlatformCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        XCTAssertThrowsError(try host.mapView.apply(configuration: invalid)) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "invalid-argument")
        }
        XCTAssertTrue(host.mapView.cameraBoundary === before)
    }

    func testFollowWithHeadingIsUnsupportedOnMacOS() {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        XCTAssertThrowsError(try host.mapView.apply(configuration: configuration(tracking: .followWithHeading))) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "unsupported-platform")
        }
        XCTAssertEqual(host.mapView.userTrackingMode, .none)
    }

    func testCameraAndRegionAreNilBeforeLayout() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        XCTAssertNil(try host.getCamera())
        XCTAssertNil(try host.getRegion())

        host.mapView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        XCTAssertGreaterThan(try XCTUnwrap(try host.getCamera()).distance, 0)
        XCTAssertGreaterThan(try XCTUnwrap(try host.getRegion()).span.latitudeDelta, 0)
    }

    func testImageAnchorPointIsHonoredOnMacOS() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        func pin(_ anchorY: Double) -> PlatformAnnotation {
            PlatformAnnotation(
                id: "img", coordinate: PlatformCoordinate(latitude: 0, longitude: 0), icon: pngIcon(width: 20, height: 40),
                calloutConsumesTapEvents: false, alpha: 1, anchorPointX: 0.5, anchorPointY: anchorY,
                isDraggable: false, isHidden: false, zPriority: 500)
        }
        try host.updateAnnotations(toAdd: [pin(1)], toChange: [], idsToRemove: [])
        let bottomCenter = host.getAnnotationView(annotation: try XCTUnwrap(host.annotationsById["img"]))
        XCTAssertEqual(bottomCenter.centerOffset, CGPoint(x: 0, y: -20))

        try host.updateAnnotations(toAdd: [], toChange: [pin(0.5)], idsToRemove: [])
        let centered = host.getAnnotationView(annotation: try XCTUnwrap(host.annotationsById["img"]))
        XCTAssertEqual(centered.centerOffset, .zero)
    }

    func testUserTrackingModeChangeReachesDart() async {
        let messenger = RecordingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        let changed = messenger.expectation(for: "onUserTrackingModeChanged", in: self)

        host.mapView(host.mapView, didChange: .none, animated: true)

        await fulfillment(of: [changed], timeout: 2)
        XCTAssertEqual(
            messenger.args(of: "onUserTrackingModeChanged").first?.first as? PlatformUserTrackingMode, PlatformUserTrackingMode.none)
    }

    func testUnavailablePointOfInterestCategoryThrowsInsteadOfDropping() throws {
        let filter = PlatformPointOfInterestFilter(mode: .including, categories: [.castle])
        XCTAssertThrowsError(try FlutterMapView.poiFilter(from: filter, category: { _ in nil })) { error in
            XCTAssertEqual((error as? MapKitHostError)?.code, "unavailable-poi-category")
        }
        XCTAssertNotNil(try FlutterMapView.poiFilter(from: filter))
    }
}

@MainActor
final class SnapshotCompositingTests: XCTestCase {
    /// A 400×400 pt map over open ocean at 0°,0° with a red image pin centred
    /// at 0.25°N 0.25°W (upper-left quadrant) and a green polygon around
    /// 0.2°S 0.2°E (lower-right quadrant).
    private func compositingHost() throws -> MapKitViewHost {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        host.mapView.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        host.mapView.setRegion(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)), animated: false)
        try host.updateAnnotations(toAdd: [PlatformAnnotation(
            id: "pin", coordinate: PlatformCoordinate(latitude: 0.25, longitude: -0.25),
            icon: pngIcon(width: 30, height: 30), calloutConsumesTapEvents: false, alpha: 1,
            anchorPointX: 0.5, anchorPointY: 0.5, isDraggable: false, isHidden: false, zPriority: 500)],
            toChange: [], idsToRemove: [])
        try host.updatePolygons(toAdd: [PlatformPolygon(
            id: "square",
            coordinates: [
                PlatformCoordinate(latitude: -0.1, longitude: 0.1),
                PlatformCoordinate(latitude: -0.1, longitude: 0.3),
                PlatformCoordinate(latitude: -0.3, longitude: 0.3),
                PlatformCoordinate(latitude: -0.3, longitude: 0.1),
            ],
            interiorPolygons: [], fillColorArgb: 0xFF00_FF00, strokeColorArgb: 0xFF00_FF00, lineWidth: 1,
            zIndex: 0, isHidden: false, consumeTapEvents: false, level: .aboveRoads)],
            toChange: [], idsToRemove: [])
        return host
    }

    private func snapshot(_ host: MapKitViewHost, annotations: Bool, overlays: Bool) throws -> NSBitmapImageRep {
        let exp = expectation(description: "snapshot")
        var bytes: Data?
        host.takeSnapshot(options: PlatformSnapshotOptions(
            showsPointsOfInterest: false, showsAnnotations: annotations, showsOverlays: overlays)) { result in
            if case .success(let data) = result { bytes = data.data }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 20)
        return try XCTUnwrap(NSBitmapImageRep(data: try XCTUnwrap(bytes)))
    }

    /// The pixel at `point` (in snapshot points, origin top-left) of `rep`.
    private func color(_ rep: NSBitmapImageRep, at point: CGPoint) throws -> NSColor {
        let scale = CGFloat(rep.pixelsWide) / 400
        let pixel = try XCTUnwrap(rep.colorAt(x: Int(point.x * scale), y: Int(point.y * scale)))
        return try XCTUnwrap(pixel.usingColorSpace(.sRGB))
    }

    private func isRed(_ c: NSColor) -> Bool { c.redComponent > 0.8 && c.greenComponent < 0.3 && c.blueComponent < 0.3 }
    private func isGreen(_ c: NSColor) -> Bool { c.greenComponent > 0.8 && c.redComponent < 0.3 && c.blueComponent < 0.3 }

    func testMacOSSnapshotCompositesAnnotationsAndOverlays() throws {
        let host = try compositingHost()
        let pin = host.mapView.convert(CLLocationCoordinate2D(latitude: 0.25, longitude: -0.25), toPointTo: host.mapView)
        let square = host.mapView.convert(CLLocationCoordinate2D(latitude: -0.2, longitude: 0.2), toPointTo: host.mapView)
        // MKMapView on macOS is unflipped; snapshot pixels run top-down.
        let pinTop = CGPoint(x: pin.x, y: host.mapView.isFlipped ? pin.y : 400 - pin.y)
        let squareTop = CGPoint(x: square.x, y: host.mapView.isFlipped ? square.y : 400 - square.y)

        let rep = try snapshot(host, annotations: true, overlays: true)

        let pinColor = try color(rep, at: pinTop)
        let squareColor = try color(rep, at: squareTop)
        XCTAssertTrue(isRed(pinColor), "pin pixel at \(pinTop) is \(pinColor)")
        XCTAssertTrue(isGreen(squareColor), "polygon pixel at \(squareTop) is \(squareColor)")
        let mirrored = try color(rep, at: CGPoint(x: pinTop.x, y: 400 - pinTop.y))
        XCTAssertFalse(isRed(mirrored), "pin drawn upside down at \(400 - pinTop.y)")
    }

    func testMacOSSnapshotDrawsMarkerAnnotations() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        host.mapView.frame = CGRect(x: 0, y: 0, width: 400, height: 400)
        host.mapView.setRegion(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)), animated: false)
        try host.updateAnnotations(toAdd: [PlatformAnnotation(
            id: "marker", coordinate: PlatformCoordinate(latitude: 0.25, longitude: -0.25),
            icon: PlatformAnnotationIcon(type: .marker, markerTintArgb: 0xFFFF_0000), calloutConsumesTapEvents: false,
            alpha: 1, anchorPointX: 0.5, anchorPointY: 1, isDraggable: false, isHidden: false, zPriority: 500)],
            toChange: [], idsToRemove: [])
        let pin = host.mapView.convert(CLLocationCoordinate2D(latitude: 0.25, longitude: -0.25), toPointTo: host.mapView)
        let pinTop = CGPoint(x: pin.x, y: host.mapView.isFlipped ? pin.y : 400 - pin.y)

        let rep = try snapshot(host, annotations: true, overlays: false)

        var reddish = 0
        for dy in stride(from: -20, through: 20, by: 2) {
            for dx in stride(from: -20, through: 20, by: 2) {
                let c = try color(rep, at: CGPoint(x: pinTop.x + CGFloat(dx), y: pinTop.y + CGFloat(dy)))
                if c.redComponent > 0.7 && c.greenComponent < 0.4 && c.blueComponent < 0.4 { reddish += 1 }
            }
        }
        XCTAssertGreaterThan(reddish, 10, "red marker balloon pixels around \(pinTop)")
    }

    func testMacOSSnapshotDrawsAnnotationsAboveOverlays() throws {
        let host = try compositingHost()
        try host.updateAnnotations(toAdd: [PlatformAnnotation(
            id: "inside", coordinate: PlatformCoordinate(latitude: -0.2, longitude: 0.2),
            icon: pngIcon(width: 30, height: 30), calloutConsumesTapEvents: false, alpha: 1,
            anchorPointX: 0.5, anchorPointY: 0.5, isDraggable: false, isHidden: false, zPriority: 500)],
            toChange: [], idsToRemove: [])
        let inside = host.mapView.convert(CLLocationCoordinate2D(latitude: -0.2, longitude: 0.2), toPointTo: host.mapView)
        let insideTop = CGPoint(x: inside.x, y: host.mapView.isFlipped ? inside.y : 400 - inside.y)

        let rep = try snapshot(host, annotations: true, overlays: true)

        let c = try color(rep, at: insideTop)
        XCTAssertTrue(isRed(c), "pin inside the polygon is drawn under it: \(c)")
    }

    func testMacOSSnapshotLeavesThemOutWhenTurnedOff() throws {
        let host = try compositingHost()
        let pin = host.mapView.convert(CLLocationCoordinate2D(latitude: 0.25, longitude: -0.25), toPointTo: host.mapView)
        let square = host.mapView.convert(CLLocationCoordinate2D(latitude: -0.2, longitude: 0.2), toPointTo: host.mapView)
        let pinTop = CGPoint(x: pin.x, y: host.mapView.isFlipped ? pin.y : 400 - pin.y)
        let squareTop = CGPoint(x: square.x, y: host.mapView.isFlipped ? square.y : 400 - square.y)

        let rep = try snapshot(host, annotations: false, overlays: false)

        XCTAssertFalse(isRed(try color(rep, at: pinTop)))
        XCTAssertFalse(isGreen(try color(rep, at: squareTop)))
    }
}

final class CountingMapView: FlutterMapView {
    var trackingModeSets = 0
    override func setUserTrackingMode(_ mode: MKUserTrackingMode, animated: Bool) { trackingModeSets += 1 }
}
