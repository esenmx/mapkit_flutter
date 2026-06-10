import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

void main() {
  group('MapKitException.fromPlatform', () {
    test('wraps any code with its diagnostics', () {
      final e = MapKitException.fromPlatform(
        PlatformException(code: 'boom', message: 'kaboom', details: 42),
      );
      check(e).isA<MapKitPlatformException>();
      final platform = e as MapKitPlatformException;
      check(platform.code).equals('boom');
      check(platform.message).equals('kaboom');
      check(platform.details).equals(42);
      check(platform.toString()).contains('boom');
    });

    test('falls back to a generic message when the platform sends none', () {
      final e = MapKitException.fromPlatform(PlatformException(code: 'x'));
      check(e.message).equals('Platform error');
    });
  });

  group('concrete exceptions', () {
    test('disposed exception names the controller', () {
      check(
        const MapKitDisposedException().message,
      ).contains('MKMapViewController');
    });

    test('unsupported platform exception carries the platform', () {
      const e = MapKitUnsupportedPlatformException(TargetPlatform.android);
      check(e.platform).equals(TargetPlatform.android);
      check(e.toString()).contains('android');
    });
  });
}
