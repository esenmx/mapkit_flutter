#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import AppKit
#endif

@objc(MapKitPlugin)
@MainActor
public final class MapKitPlugin: NSObject, @preconcurrency FlutterPlugin {
    private static let viewType = "dev.mapkit.flutter/map_view"

    public nonisolated static func register(with registrar: FlutterPluginRegistrar) {
        // Plugin registration runs on the main thread; the factory and view
        // host are main-actor isolated. macOS's GeneratedPluginRegistrant
        // calls this from a nonisolated context, so assume isolation here.
        MainActor.assumeIsolated {
            let factory = MapKitViewFactory(withRegistrar: registrar)
            #if os(iOS)
            registrar.register(
                factory,
                withId: viewType,
                gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded
            )
            #elseif os(macOS)
            registrar.register(factory, withId: viewType)
            #endif
        }
    }
}
