import Flutter
import MapKit
import UIKit
import XCTest
@testable import mapkit_flutter

/// Swallows every message; the iOS tests only inspect native state.
final class NoopMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {}

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {}

    func setMessageHandlerOnChannel(
        _ channel: String,
        binaryMessageHandler handler: FlutterBinaryMessageHandler?
    ) -> FlutterBinaryMessengerConnection {
        0
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {}
}

private func annotation(_ id: String, callout: Bool = false) -> PlatformAnnotation {
    PlatformAnnotation(
        id: id,
        coordinate: PlatformCoordinate(latitude: 1, longitude: 2),
        icon: PlatformAnnotationIcon(type: .marker),
        calloutConsumesTapEvents: callout,
        alpha: 1,
        anchorPointX: 0.5,
        anchorPointY: 1,
        isDraggable: true,
        isHidden: false,
        zPriority: 500
    )
}

@MainActor
final class RunnerTests: XCTestCase {
    func testEvChargerMapsOnEveryOS() {
        XCTAssertEqual(PlatformPointOfInterestCategory.evCharger.mkCategory, .evCharger)
    }

    func testCalloutRecognizerAddedOncePerView() throws {
        let host = MapKitViewHost(messenger: NoopMessenger(), id: 0)
        try host.updateAnnotations(toAdd: [annotation("a", callout: true)], toChange: [], idsToRemove: [])
        let view = MKMarkerAnnotationView(annotation: host.annotationsById["a"], reuseIdentifier: nil)

        host.mapView(host.mapView, didSelect: view)
        host.mapView(host.mapView, didSelect: view)

        let recognizers = (view.gestureRecognizers ?? []).filter { $0 is InfoWindowTapGestureRecognizer }
        XCTAssertEqual(recognizers.count, 1)
    }
}
