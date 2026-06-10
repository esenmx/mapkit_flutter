import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/_internal/map_object_updates.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

import '_helpers/controller_harness.dart';
import '_helpers/fixtures.dart';
import '_helpers/platform_fixtures.dart';
import '_helpers/recorded_call.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ControllerHarness harness;

  setUp(() => harness = ControllerHarness());
  tearDown(() => harness.dispose());

  group('outbound — camera', () {
    test('setCamera forwards the camera and the animated flag', () async {
      await harness.controller.setCamera(sampleCamera, animated: false);
      final (camera, animated) = harness.expectSetCamera();
      check(camera.distance).equals(1200);
      check(animated).isFalse();
    });

    test('setCamera animates by default', () async {
      await harness.controller.setCamera(sampleCamera);
      check(harness.expectSetCamera().$2).isTrue();
    });

    test('setRegion forwards center and span', () async {
      await harness.controller.setRegion(sampleRegion, animated: false);
      final (region, _) = harness.expectSetRegion();
      check(region.center.latitude).equals(applePark.latitude);
      check(region.span.latitudeDelta).equals(0.05);
    });

    test('setCenter forwards the coordinate', () async {
      await harness.controller.setCenter(applePark);
      final (coordinate, animated) = harness.expectSetCenter();
      check(coordinate.longitude).equals(applePark.longitude);
      check(animated).isTrue();
    });

    test('camera getter parses the host camera', () async {
      harness.host.camera = platformCamera(
        latitude: 10,
        longitude: 20,
        distance: 4321,
        heading: 90,
        pitch: 15,
      );
      final camera = await harness.controller.camera;
      check(
        camera.centerCoordinate,
      ).equals(const CLLocationCoordinate2D(latitude: 10, longitude: 20));
      check(camera.distance).equals(4321);
      check(camera.heading).equals(90);
      check(camera.pitch).equals(15);
    });

    test('region getter parses center + span', () async {
      harness.host.region = platformRegion(
        latitude: 10,
        longitude: 20,
        latitudeDelta: 1,
        longitudeDelta: 2,
      );
      final region = await harness.controller.region;
      check(
        region.center,
      ).equals(const CLLocationCoordinate2D(latitude: 10, longitude: 20));
      check(
        region.span,
      ).equals(const MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 2));
    });
  });

  group('outbound — coordinate conversion', () {
    test('convertToPoint returns an Offset when the host has layout', () async {
      harness.host.point = platformPoint(100, 200);
      final p = await harness.controller.convertToPoint(applePark);
      check(p).isNotNull();
      check(p!.dx).equals(100);
      check(p.dy).equals(200);
    });

    test('convertToPoint returns null without layout', () async {
      harness.host.point = null;
      check(await harness.controller.convertToPoint(applePark)).isNull();
    });

    test('convertToCoordinate returns the coordinate under a point', () async {
      harness.host.coordinate = platformCoord(1, 2);
      final c = await harness.controller.convertToCoordinate(
        const Offset(5, 5),
      );
      check(c).equals(const CLLocationCoordinate2D(latitude: 1, longitude: 2));
      check(harness.host.calls.lastRecorded.name).equals('convertToCoordinate');
    });

    test('convertToCoordinate returns null without layout', () async {
      harness.host.coordinate = null;
      check(await harness.controller.convertToCoordinate(Offset.zero)).isNull();
    });
  });

  group('outbound — callout', () {
    test('showCallout forwards the id', () async {
      await harness.controller.showCallout(const MKAnnotationId('a'));
      check(harness.expectLast<String>('showCallout')).equals('a');
    });

    test('hideCallout forwards the id', () async {
      await harness.controller.hideCallout(const MKAnnotationId('a'));
      harness.expectLastCall('hideCallout');
    });

    test('isCalloutShown returns host bool', () async {
      harness.host.calloutShown = true;
      check(
        await harness.controller.isCalloutShown(const MKAnnotationId('a')),
      ).isTrue();
    });
  });

  group('outbound — polish features', () {
    test('takeSnapshot forwards the options', () async {
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
        harness.host.lookAroundResult = true;
        final ok = await harness.controller.openLookAround(
          const CLLocationCoordinate2D(latitude: 37, longitude: -122),
        );
        check(ok).isTrue();
        check(
          harness.expectLast<PlatformCoordinate>('openLookAround').latitude,
        ).equals(37);
      },
    );

    test('addTileOverlay forwards a typed overlay', () async {
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
      await harness.controller.removeTileOverlay(const MKTileOverlayId('osm'));
      check(harness.expectLast<String>('removeTileOverlay')).equals('osm');
    });
  });

  group('outbound — diff updates', () {
    test('updateAnnotations forwards mapped platform lists', () async {
      final before = {annotation('a')};
      final after = {annotation('a', coordinate: infiniteLoop)};
      await harness.controller.updateAnnotations(
        MapObjectUpdates.between(before, after, idOf: (a) => a.id.value),
      );
      final args = harness.expectLast<AnnotationUpdate>('updateAnnotations');
      check(args.$2).length.equals(1); // toChange
    });
  });

  group('inbound — handler routes to sink', () {
    test('onCameraMoveStarted', () {
      harness.controller.eventHandler.onCameraMoveStarted();
      harness.sink.events.expectOnlyEvent('cameraMoveStarted');
    });

    test('onCameraMove delivers an MKMapCamera', () {
      harness.controller.eventHandler.onCameraMove(
        platformCamera(latitude: 1, longitude: 2, distance: 900),
      );
      check(harness.expectSink<MKMapCamera>('cameraMove').distance).equals(900);
    });

    test('onAnnotationTap', () {
      harness.controller.eventHandler.onAnnotationTap('a');
      check(
        harness.expectSink<MKAnnotationId>('annotationTap'),
      ).equals(const MKAnnotationId('a'));
    });

    test('annotation drag lifecycle', () {
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
      harness.controller.eventHandler.onMapTap(platformCoord(10, 20));
      check(
        harness.expectSink<CLLocationCoordinate2D>('mapTap'),
      ).equals(const CLLocationCoordinate2D(latitude: 10, longitude: 20));
    });

    test('onDidFailLoadingMap delivers the error description', () {
      harness.controller.eventHandler.onDidFailLoadingMap('offline');
      check(
        harness.sink.events.single,
      ).equals(('didFailLoadingMap', 'offline'));
    });

    test('onDidFailToLocateUser delivers the error description', () {
      harness.controller.eventHandler.onDidFailToLocateUser('denied');
      check(
        harness.sink.events.single,
      ).equals(('didFailToLocateUser', 'denied'));
    });
  });

  group('errors', () {
    test('disposed controller throws MapKitDisposedException', () async {
      await harness.dispose();
      await check(
        harness.controller.setCamera(sampleCamera),
      ).throws<MapKitDisposedException>();
    });

    test('snapshot failure surfaces its stable code', () async {
      harness.host.errorToThrow = PlatformException(
        code: 'snapshot-failed',
        message: 'Snapshot produced no image data.',
      );
      check(
        await catchMapKit<MapKitPlatformException>(
          () => harness.controller.takeSnapshot(),
        ),
      ).has((e) => e.code, 'code').equals('snapshot-failed');
    });

    test('generic platform error maps to MapKitPlatformException', () async {
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

    test('queued calls after a failure still run', () async {
      harness.host.errorToThrow = PlatformException(code: 'boom');
      final failing = harness.controller.setCamera(sampleCamera);
      final following = harness.controller.setCenter(applePark);
      await check(failing).throws<MapKitPlatformException>();
      await following;
      harness.expectLastCall('setCenter');
    });
  });
}
