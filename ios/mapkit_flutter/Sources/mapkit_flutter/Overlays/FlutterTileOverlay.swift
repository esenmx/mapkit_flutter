import Flutter
import Foundation
import MapKit

final class FlutterTileOverlay: MKTileOverlay, @unchecked Sendable {
    let id: String
    var alpha: CGFloat = 1.0
    var overlayLevel: MKOverlayLevel = .aboveRoads

    init(fromPlatform data: PlatformTileOverlay) {
        self.id = data.id
        super.init(urlTemplate: data.urlTemplate)
        self.tileSize = CGSize(width: CGFloat(data.tileSize), height: CGFloat(data.tileSize))
        self.minimumZ = Int(data.minimumZ)
        self.maximumZ = Int(data.maximumZ)
        self.canReplaceMapContent = data.canReplaceMapContent
        self.alpha = CGFloat(data.alpha)
        self.overlayLevel = data.level.mkLevel
    }
}
