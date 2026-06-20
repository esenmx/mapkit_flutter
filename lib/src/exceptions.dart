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
sealed class MapKitException implements Exception {
  const MapKitException(this.message);

  /// Wraps a raw [PlatformException] from the platform channel into a
  /// [MapKitException].
  @internal
  factory MapKitException.fromPlatform(PlatformException e) =>
      MapKitPlatformException(
        code: e.code,
        message: e.message ?? 'Platform error',
        details: e.details,
      );

  /// Human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'MapKitException: $message';
}

/// Thrown when a method is called on a controller whose map view has already
/// been disposed.
final class MapKitDisposedException extends MapKitException {
  const MapKitDisposedException()
    : super('The MKMapViewController has been disposed.');
}

/// Thrown when an `MKMapView` is built on a non-Apple platform (anything other
/// than iOS or macOS). `mapkit_flutter`
/// wraps Apple's MapKit, so there is no cross-platform fallback — this
/// surfaces loudly instead of silently rendering an empty box.
final class MapKitUnsupportedPlatformException extends MapKitException {
  const MapKitUnsupportedPlatformException(this.platform)
    : super(
        'mapkit_flutter supports iOS and macOS only; '
        'MKMapView cannot render here.',
      );

  /// The platform the widget was built on.
  final TargetPlatform platform;

  @override
  String toString() =>
      'MapKitUnsupportedPlatformException: '
      'mapkit_flutter supports iOS and macOS only and '
      'cannot render on $platform.';
}

/// A failure reported by the native MapKit layer. Carries the original
/// platform [code] and [details] for diagnostics.
final class MapKitPlatformException extends MapKitException {
  const MapKitPlatformException({
    required this.code,
    required String message,
    this.details,
  }) : super(message);

  /// The platform error code (from the Swift side).
  final String code;

  /// Optional structured details from the platform.
  final Object? details;

  @override
  String toString() => 'MapKitPlatformException($code): $message';
}
