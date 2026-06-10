import Flutter
import UIKit

@objc(MapKitPlugin)
@MainActor
public final class MapKitPlugin: NSObject, @preconcurrency FlutterPlugin {
    private static let viewType = "dev.mapkit.flutter/map_view"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = MapKitViewFactory(withRegistrar: registrar)
        registrar.register(
            factory,
            withId: viewType,
            gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded
        )
    }
}
