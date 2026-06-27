import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import AppKit
import FlutterMacOS
#endif

@MainActor
public class MapKitViewFactory: NSObject, @preconcurrency FlutterPlatformViewFactory {

    var registrar: FlutterPluginRegistrar

    public init(withRegistrar registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    // Creation no longer carries a payload; Dart pushes the full initial state
    // over the type-safe `MapKitHostApi.initialize` call once the view exists.
    #if os(iOS)
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return MapKitViewHost(withFrame: frame, withRegistrar: registrar, withId: viewId)
    }
    #elseif os(macOS)
    public func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        // macOS returns the NSView directly (no FlutterPlatformView protocol);
        // the container owns the host for the platform view's lifetime.
        let host = MapKitViewHost(withFrame: .zero, withRegistrar: registrar, withId: viewId)
        return MapKitContainerView(host: host)
    }
    #endif

    #if os(iOS)
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    #elseif os(macOS)
    public func createArgsCodec() -> (any FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    #endif
}

#if os(macOS)
/// Owns the `MapKitViewHost` (which holds the channel handler + map delegate)
/// for as long as Flutter retains the platform view, and hosts the map view.
final class MapKitContainerView: NSView {
    let host: MapKitViewHost

    init(host: MapKitViewHost) {
        self.host = host
        super.init(frame: .zero)
        let map = host.mapView
        map.frame = bounds
        map.autoresizingMask = [.width, .height]
        addSubview(map)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
}
#endif
