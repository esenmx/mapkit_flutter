/// Stable error codes; the Dart side surfaces them as
/// `MapKitPlatformException.code`. Keep in sync with `pigeons/messages.dart`.
enum MapKitErrorCode: String {
    case snapshotFailed = "snapshot-failed"
    case lookAroundFailed = "look-around-failed"
    case unsupportedPlatform = "unsupported-platform"
    case duplicateId = "duplicate-id"
    case invalidIcon = "invalid-icon"
    case unavailablePoiCategory = "unavailable-poi-category"
    case invalidArgument = "invalid-argument"
}

func mapKitError(_ code: MapKitErrorCode, _ message: String) -> MapKitHostError {
    MapKitHostError(code: code.rawValue, message: message, details: nil)
}
