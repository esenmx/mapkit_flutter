import Flutter
import Foundation

@MainActor
public class MapKitViewFactory: NSObject, @preconcurrency FlutterPlatformViewFactory {

    var registrar: FlutterPluginRegistrar

    public init(withRegistrar registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        // Creation no longer carries a payload; Dart pushes the full initial
        // state over the type-safe `MapKitHostApi.initialize` call once the
        // platform view exists.
        return MapKitViewHost(withFrame: frame, withRegistrar: registrar, withId: viewId)
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
