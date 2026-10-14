import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

import '_helpers/controller_harness.dart';
import '_helpers/fixtures.dart';
import '_helpers/platform_fixtures.dart';
import '_helpers/recorded_call.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ControllerHarness buildHarness() => ControllerHarness.autoTearDown();

  group('outbound — camera', () {
    test('setCamera forwards the camera and the animated flag', () async {
      final harness = buildHarness();
      await harness.controller.setCamera(sampleCamera, animated: false);
      final (camera, animated) = harness.expectSetCamera();
      check(camera.distance).equals(1200);
      check(animated).isFalse();
    });

    test('setCamera animates by default', () async {
      final harness = buildHarness();
      await harness.controller.setCamera(sampleCamera);
      check(harness.expectSetCamera().$2).isTrue();
    });

    test('setRegion forwards center and span', () async {
      final harness = buildHarness();
      await harness.controller.setRegion(sampleRegion, animated: false);
      final (region, _) = harness.expectSetRegion();
      check(region.center.latitude).equals(applePark.latitude);
      check(region.span.latitudeDelta).equals(0.05);
    });

    test('setCenter forwards the coordinate', () async {
      final harness = buildHarness();
      await harness.controller.setCenter(applePark);
      final (coordinate, animated) = harness.expectSetCenter();
      check(coordinate.longitude).equals(applePark.longitude);
      check(animated).isTrue();
    });

    test('camera getter parses the host camera', () async {
      final harness = buildHarness();
      harness.host.camera = platformCamera(
        latitude: 10,
        longitude: 20,
        distance: 4321,
        heading: 90,
        pitch: 15,
      );
      final camera = await harness.controller.camera;
      const target = CLLocationCoordinate2D(latitude: 10, longitude: 20);
      check(camera.centerCoordinate).equals(target);
      check(camera.distance).equals(4321);
      check(camera.heading).equals(90);
      check(camera.pitch).equals(15);
    });

    test('region getter parses center + span', () async {
      final harness = buildHarness();
      harness.host.region = platformRegion(
        latitude: 10,
        longitude: 20,
        latitudeDelta: 1,
        longitudeDelta: 2,
      );
      final region = await harness.controller.region;
      const center = CLLocationCoordinate2D(latitude: 10, longitude: 20);
      const span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2);
      check(region.center).equals(center);
      check(region.span).equals(span);
    });
  });

  group('outbound — coordinate conversion', () {
    test('convertToPoint returns an Offset when the host has layout', () async {
      final harness = buildHarness();
      harness.host.point = platformPoint(100, 200);
      final p = await harness.controller.convertToPoint(applePark);
      check(p).isNotNull()
        ..has((o) => o.dx, 'dx').equals(100)
        ..has((o) => o.dy, 'dy').equals(200);
    });

    test('convertToPoint returns null without layout', () async {
      final harness = buildHarness();
      harness.host.point = null;
      check(await harness.controller.convertToPoint(applePark)).isNull();
    });

    test('convertToCoordinate returns the coordinate under a point', () async {
      final harness = buildHarness();
      harness.host.coordinate = platformCoord(1, 2);
      final c = await harness.controller.convertToCoordinate(
        const Offset(5, 5),
      );
      check(c).equals(const CLLocationCoordinate2D(latitude: 1, longitude: 2));
      check(harness.host.calls.lastRecorded().name)
          .equals('convertToCoordinate');
    });

    test('convertToCoordinate returns null without layout', () async {
      final harness = buildHarness();
      harness.host.coordinate = null;
      check(await harness.controller.convertToCoordinate(.zero)).isNull();
    });
  });

  group('outbound — callout', () {
    test('showCallout forwards the id', () async {
      final harness = buildHarness();
      await harness.controller.showCallout(const MKAnnotationId('a'));
      check(harness.expectLast<String>('showCallout')).equals('a');
    });

    test('hideCallout forwards the id', () async {
      final harness = buildHarness();
      await harness.controller.hideCallout(const MKAnnotationId('a'));
      harness.expectLastCall('hideCallout');
    });

    test('isCalloutShown returns host bool', () async {
      final harness = buildHarness();
      harness.host.calloutShown = true;
      const annotationId = MKAnnotationId('a');
      check(await harness.controller.isCalloutShown(annotationId)).isTrue();
    });
  });

  group('outbound — polish features', () {
    test('takeSnapshot forwards the options', () async {
      final harness = buildHarness();
      await harness.controller.takeSnapshot(
        const MKMapSnapshotOptions(showsBuildings: false, showsOverlays: false),
      );
      final options = harness.expectLast<PlatformSnapshotOptions>(
        'takeSnapshot',
      );
      check(options.showsBuildings).isFalse();
      check(options.showsPointsOfInterest).isTrue();
      check(options.showsAnnotations).isTrue();
      check(options.showsOverlays).isFalse();
    });

    test(
      'openLookAround forwards the coordinate and returns the native bool',
      () async {
        final harness = buildHarness();
        harness.host.lookAroundResult = true;
        final ok = await harness.controller.openLookAround(
          const CLLocationCoordinate2D(latitude: 37, longitude: -122),
        );
        check(ok).isTrue();
        final sent = harness.expectLast<PlatformCoordinate>('openLookAround');
        check(sent.latitude).equals(37);
      },
    );

    test('addTileOverlay forwards a typed overlay', () async {
      final harness = buildHarness();
      await harness.controller.addTileOverlay(
        const MKTileOverlay(
          id: MKTileOverlayId('osm'),
          urlTemplate: 'https://t/{z}/{x}/{y}.png',
          minimumZ: 3,
          maximumZ: 17,
          canReplaceMapContent: true,
        ),
      );
      final o = harness.expectLast<PlatformTileOverlay>('addTileOverlay');
      check(o.id).equals('osm');
      check(o.minimumZ).equals(3);
      check(o.canReplaceMapContent).isTrue();
    });

    test('removeTileOverlay forwards id only', () async {
      final harness = buildHarness();
      await harness.controller.removeTileOverlay(const MKTileOverlayId('osm'));
      check(harness.expectLast<String>('removeTileOverlay')).equals('osm');
    });
  });

  group('outbound — diff updates', () {
    test('updateAnnotations forwards mapped platform lists', () async {
      final harness = buildHarness();
      final before = {annotation('a')};
      final after = {annotation('a', coordinate: infiniteLoop)};
      await harness.controller.updateAnnotations(
        .between(before, after, idOf: (a) => a.id.value),
      );
      final args = harness.expectLast<AnnotationUpdate>('updateAnnotations');
      check(args.$2).length.equals(1); // toChange
    });
  });

  group('inbound — handler routes to sink', () {
    test('onCameraMoveStarted', () {
      final harness = buildHarness();
      harness.controller.eventHandler.onCameraMoveStarted();
      harness.sink.events.expectOnlyEvent('cameraMoveStarted');
    });

    test('onCameraMove delivers an MKMapCamera', () {
      final harness = buildHarness();
      harness.controller.eventHandler.onCameraMove(
        platformCamera(latitude: 1, longitude: 2, distance: 900),
      );
      check(harness.expectSink<MKMapCamera>('cameraMove').distance).equals(900);
    });

    test('onAnnotationTap', () {
      final harness = buildHarness();
      harness.controller.eventHandler.onAnnotationTap('a');
      final sunk = harness.expectSink<MKAnnotationId>('annotationTap');
      check(sunk).equals(const MKAnnotationId('a'));
    });

    test('annotation drag lifecycle', () {
      final harness = buildHarness();
      harness.controller.eventHandler
        ..onAnnotationDragStart('a', platformCoord(1, 2))
        ..onAnnotationDrag('a', platformCoord(1.5, 2.5))
        ..onAnnotationDragEnd('a', platformCoord(2, 3));
      harness.sink.events.expectEventNames([
        'annotationDragStart',
        'annotationDrag',
        'annotationDragEnd',
      ]);
    });

    test('onMapTap delivers a coordinate', () {
      final harness = buildHarness();
      harness.controller.eventHandler.onMapTap(platformCoord(10, 20));
      const target = CLLocationCoordinate2D(latitude: 10, longitude: 20);
      final sunk = harness.expectSink<CLLocationCoordinate2D>('mapTap');
      check(sunk).equals(target);
    });

    test('onDidFailLoadingMap delivers the error description', () {
      final harness = buildHarness();
      harness.controller.eventHandler.onDidFailLoadingMap('offline');
      final event = harness.sink.events.single;
      check(event).equals(('didFailLoadingMap', 'offline'));
    });

    test('onDidFailToLocateUser delivers the error description', () {
      final harness = buildHarness();
      harness.controller.eventHandler.onDidFailToLocateUser('denied');
      final event = harness.sink.events.single;
      check(event).equals(('didFailToLocateUser', 'denied'));
    });
  });

  group('errors', () {
    test('disposed controller throws MapKitDisposedException', () async {
      final harness = buildHarness();
      await harness.dispose();
      final setCamera = harness.controller.setCamera(sampleCamera);
      await check(setCamera).throws<MapKitDisposedException>();
    });

    test('snapshot failure surfaces its stable code', () async {
      final harness = buildHarness();
      harness.host.errorToThrow = PlatformException(
        code: 'snapshot-failed',
        message: 'Snapshot produced no image data.',
      );
      check(
        await catchMapKit<MapKitPlatformException>(
          harness.controller.takeSnapshot,
        ),
      ).has((e) => e.code, 'code').equals('snapshot-failed');
    });

    test('generic platform error maps to MapKitPlatformException', () async {
      final harness = buildHarness();
      harness.host.errorToThrow = PlatformException(
        code: 'boom',
        message: 'kaboom',
      );
      check(
        await catchMapKit<MapKitPlatformException>(
          () => harness.controller.setCamera(sampleCamera),
        ),
      ).has((e) => e.code, 'code').equals('boom');
    });

    test('non-platform error propagates unwrapped', () async {
      final harness = buildHarness();
      final exception = Exception('custom host error');
      harness.host.errorToThrow = exception;

      Object? caughtError;
      StackTrace? caughtTrace;
      try {
        await harness.controller.setCamera(sampleCamera);
      } on Object catch (e, st) {
        caughtError = e;
        caughtTrace = st;
      }
      check(caughtError).identicalTo(exception);
      check(caughtTrace.toString()).contains('FakeHostApi._record');
    });

    test(
      'Error subtype propagates unwrapped through the generic catch',
      () async {
        final harness = buildHarness();
        final error = StateError('host invariant violated');
        harness.host.errorToThrow = error;

        Object? caughtError;
        StackTrace? caughtTrace;
        try {
          await harness.controller.setCamera(sampleCamera);
        } on Object catch (e, st) {
          caughtError = e;
          caughtTrace = st;
        }
        check(caughtError).identicalTo(error);
        check(caughtTrace.toString()).contains('FakeHostApi._record');
      },
    );

    test('queued calls after a failure still run', () async {
      final harness = buildHarness();
      harness.host.errorToThrow = PlatformException(code: 'boom');
      final failing = harness.controller.setCamera(sampleCamera);
      final following = harness.controller.setCenter(applePark);
      await check(failing).throws<MapKitPlatformException>();
      await following;
      harness.expectLastCall('setCenter');
    });
  });
}
