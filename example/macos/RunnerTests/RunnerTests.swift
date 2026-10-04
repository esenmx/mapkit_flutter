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

private func configuration(
    scale: Bool = false,
    tracking: PlatformUserTrackingMode = .none,
    kind: PlatformMapKind = .standard,
    trackingButton: Bool = false
) -> PlatformMapConfiguration {
    PlatformMapConfiguration(
        kind: kind,
        emphasisStyle: .standard,
        elevationStyle: .flat,
        showsTraffic: false,
        showsCompass: true,
        showsScale: scale,
        showsUserLocation: false,
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

private func circle(_ id: String, zIndex: Int64 = 0, hidden: Bool = false) -> PlatformCircle {
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
        level: .aboveRoads
    )
}

@MainActor
final class RunnerTests: XCTestCase {
    func testDisposeRemovesEveryHandler() throws {
        let messenger = ConnectionCountingMessenger()
        let host = MapKitViewHost(messenger: messenger, id: 0)
        XCTAssertFalse(messenger.live.isEmpty)

        try host.dispose()

        XCTAssertEqual(messenger.live, [])
        XCTAssertNil(host.mapView.delegate)
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

    func testCalloutOffsetIgnoresViewPosition() {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let flutterAnnotation = FlutterAnnotation(fromPlatform: annotation("a"))
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
            toAdd: [circle("low", zIndex: 0), circle("high", zIndex: 1)], toChange: [], idsToRemove: [])
        let circleTap = messenger.expectation(for: "onCircleTap", in: self)

        TouchHandler.handleMapTap(
            at: CLLocationCoordinate2D(latitude: 0, longitude: 0), flutterApi: host.flutterApi, in: host.mapView)

        await fulfillment(of: [circleTap], timeout: 2)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(messenger.args(of: "onCircleTap").map { $0.compactMap { $0 as? String } }, [["high"]])
    }

    func testTrackingModeReappliedOnlyWhenItChanges() {
        let view = CountingMapView()

        view.apply(configuration: configuration(tracking: .follow))
        view.apply(configuration: configuration(scale: true, tracking: .follow))
        XCTAssertEqual(view.trackingModeSets, 1)

        view.apply(configuration: configuration(scale: true, tracking: .none))
        XCTAssertEqual(view.trackingModeSets, 2)
    }

    func testReAddingTileOverlayReplacesIt() throws {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)
        let tiles = PlatformTileOverlay(
            id: "",
            urlTemplate: "https://tile.example.com/{z}/{x}/{y}.png",
            minimumZ: 0,
            maximumZ: 19,
            tileSize: 256,
            canReplaceMapContent: false,
            alpha: 1,
            level: .aboveRoads
        )

        try host.addTileOverlay(overlay: tiles)
        try host.addTileOverlay(overlay: tiles)

        XCTAssertEqual(host.mapView.overlays.count, 1)
    }

    func testTrackingButtonAppliesOnMacOS() {
        let host = MapKitViewHost(messenger: RecordingMessenger(), id: 0)

        host.mapView.apply(configuration: configuration(trackingButton: true))

        XCTAssertTrue(host.mapView.showsUserTrackingButton)
    }
}

final class CountingMapView: FlutterMapView {
    var trackingModeSets = 0
    override func setUserTrackingMode(_ mode: MKUserTrackingMode, animated: Bool) { trackingModeSets += 1 }
}
