import Foundation
import os

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

/// Resolves this view's `MapKitFlutterApi` registration on demand (Dart
/// registers it in `onPlatformViewCreated`, after the native view exists) and
/// delivers events on the main actor in creation order.
@MainActor
final class FlutterEventSender {
    private let resolve: () -> MapKitFlutterApi?

    init(registrar: FlutterPluginRegistrar, name: String) {
        self.resolve = { MapKitFlutterApiRegistrar.getInstance(registrar: registrar, name: name) }
    }

    func send(_ event: @escaping @MainActor (MapKitFlutterApi) throws -> Void) {
        let resolve = self.resolve
        Task { @MainActor in
            guard let api = resolve() else { return }
            do {
                try event(api)
            } catch {
                EventDeliveryFailure.report(error)
            }
        }
    }
}

/// An event that failed to arrive. Exceptions from Flutter callbacks never get
/// here: Dart reports those itself and returns cleanly. What is left is a
/// stale registration whose isolate went away without unregistering, or a
/// message Dart could not decode. Neither is the app's misuse and neither can
/// be reported to Dart over the callback that failed, so it is logged.
@MainActor
enum EventDeliveryFailure {
    private static let log = Logger(subsystem: "dev.mapkit.flutter", category: "events")

    /// Replaced by tests to observe failures.
    static var report: (Error) -> Void = { error in
        if (error as? MapKitHostError)?.code == "channel-error" {
            log.debug("Event not delivered: \(String(describing: error), privacy: .public)")
        } else {
            log.error("Event failed: \(String(describing: error), privacy: .public)")
        }
    }
}
