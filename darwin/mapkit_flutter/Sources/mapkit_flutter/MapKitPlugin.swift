#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import AppKit
#endif

@objc(MapKitPlugin)
@MainActor
public final class MapKitPlugin: NSObject, FlutterPlugin {
    private static let viewType = "dev.mapkit.flutter/map_view"

    public static func register(with registrar: FlutterPluginRegistrar) {
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
