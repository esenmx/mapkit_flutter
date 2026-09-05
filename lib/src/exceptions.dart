import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:meta/meta.dart';

/// Base type for every error surfaced by `mapkit_flutter`.
///
/// Catch this to handle any map failure, or switch on the concrete subtypes
/// for finer control:
///
/// ```dart
/// try {
///   await controller.takeSnapshot();
/// } on MapKitPlatformException catch (e) {
///   // Native failure with a stable code, e.g. 'snapshot-failed'.
/// } on MapKitException {
///   // Anything else (e.g. controller already disposed).
/// }
/// ```
@immutable
sealed class const MapKitException(
  /// Human-readable description of what went wrong.
  final String message,
) implements Exception {
  /// Creates a new MapKitException object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  this;

  /// Wraps a raw [PlatformException] from the platform channel into a
  /// [MapKitException].
  @internal
  factory fromPlatform(PlatformException e) => MapKitPlatformException(
    code: e.code,
    message: e.message ?? 'Platform error',
    details: e.details,
  );

  @override
  String toString() => 'MapKitException: $message';
}

/// Thrown when a method is called on a controller whose map view has already
/// been disposed.
final class MapKitDisposedException extends MapKitException {
  /// Creates a new MapKitDisposedException object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  const new() : super('The MKMapViewController has been disposed.');
}

/// Thrown when an `MKMapView` is built on a non-Apple platform (anything other
/// than iOS or macOS). `mapkit_flutter`
/// wraps Apple's MapKit, so there is no cross-platform fallback — this
/// surfaces loudly instead of silently rendering an empty box.
final class const MapKitUnsupportedPlatformException(
  /// The platform the widget was built on.
  final TargetPlatform platform,
) extends MapKitException {
  /// Creates a new MapKitUnsupportedPlatformException object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  this
    : super(
        'mapkit_flutter supports iOS and macOS only; '
        'MKMapView cannot render here.',
      );

  @override
  String toString() =>
      'MapKitUnsupportedPlatformException: '
      'mapkit_flutter supports iOS and macOS only and '
      'cannot render on $platform.';
}

/// A failure reported by the native MapKit layer. Carries the original
/// platform [code] and [details] for diagnostics.
final class const MapKitPlatformException({
  /// The platform error code (from the Swift side).
  required final String code,
  required String message,

  /// Optional structured details from the platform.
  final Object? details,
}) extends MapKitException {
  /// Creates a new MapKitPlatformException object.
  ///
  /// See: https://developer.apple.com/documentation/mapkit
  this : super(message);

  @override
  String toString() => 'MapKitPlatformException($code): $message';
}
