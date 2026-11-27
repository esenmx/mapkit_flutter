# Setup and platform differences

## Why use it

- **No API key, no extra SDK.** MapKit ships with iOS and macOS.
  `google_maps_flutter` needs a Google Maps API key and bundles Google's Maps
  SDK on iOS, and has no macOS support.
- **No platform view to write.** Doing it yourself means a `UiKitView` /
  `AppKitView`, a platform channel and Swift delegate code. Here, pins and
  shapes are plain Dart sets that the package diffs onto the native map on every
  rebuild, and the controller is an interface you can mock in unit tests.
- **Apple's names.** Types are named after their MapKit counterparts
  (`MKMapCamera`, `MKPolyline`, `CLLocationCoordinate2D`), so Apple's
  documentation applies as-is, and they don't clash with `google_maps_flutter`,
  `mapbox_maps_flutter` or `flutter_map` types in a cross-platform app.
- **Mistakes fail loudly.** Invalid values, and iOS-only settings used on macOS
  ([differences](#ios-and-macos-differences)), throw in every build mode instead
  of being silently ignored.

MapKit doesn't exist on Android: building `MKMapView` there throws a
`MapKitUnsupportedPlatformException`. For a cross-platform app, pair this
package with `google_maps_flutter` behind a platform check.

## Requirements

| | Minimum |
| --- | --- |
| iOS | 17.0 |
| macOS | 14.0 |
| Xcode | 16 |

Raise the app's deployment targets to the plugin's floor:

- **iOS 17.0** — `IPHONEOS_DEPLOYMENT_TARGET` on the Runner target (or Podfile
  `platform :ios, '17.0'`).
- **macOS 14.0** — `MACOSX_DEPLOYMENT_TARGET` on the Runner target (or Podfile
  `platform :osx, '14.0'`).

A Swift Package Manager app left on Flutter's default macOS 12.0 fails to build
with "requires minimum platform version 14.0".

## Showing the user's location

If you set `showsUserLocation: true`, add this to `ios/Runner/Info.plist` (on
macOS, to `macos/Runner/Info.plist`, plus the Location sandbox entitlement):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to show your current location on the map.</string>
```

Like `MKMapView`, the map never asks for location permission itself: request
when-in-use authorization in your app (e.g. with `permission_handler` or a
`CLLocationManager` channel) at the moment that makes sense for your UI. Without
it, `onDidFailToLocateUser` reports the failure.

## iOS and macOS differences

| | iOS | macOS |
| --- | --- | --- |
| `calloutConsumesTapEvents` / `onCalloutTap` | ✓ | throws (default callout) |
| Image-icon `anchorPoint` | ✓ | ✓ |
| `userTrackingMode: followWithHeading` | ✓ | throws |
| Snapshot annotation/overlay compositing | ✓ | ✓ |
| `selectableMapFeatures` + `onMapFeatureSelected` | ✓ | throws |
| `insetsLayoutMarginsFromSafeArea: false` | ✓ | throws |
| `layoutMargins` | ✓ | throws |
| `openLookAround` | ✓ | throws `unsupported-platform` |
| `showsUserTrackingButton` | ✓ | ✓ |
| `onCameraMove` | continuous | continuous |

"Throws" means building `MKMapView` with that setting on macOS throws a
`MapKitUnsupportedPlatformException` naming it. `openLookAround` is a controller
call instead: on macOS it fails with a `MapKitPlatformException` whose code is
`unsupported-platform`.
