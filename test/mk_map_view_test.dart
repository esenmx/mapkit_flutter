import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';

import '_helpers/fake_host_api.dart';
import '_helpers/fixtures.dart';
import '_helpers/platform_fixtures.dart';
import '_helpers/recorded_call.dart';

void main() {
  late FakeHostApi host;
  var nextViewId = 0;

  setUp(() {
    host = FakeHostApi();
    nextViewId++;
  });

  MKMapViewController controllerFactory(MKMapViewEventSink sink) =>
      MKMapViewController.create(viewId: nextViewId, sink: sink, hostApi: host);

  Widget map({
    Set<MKPointAnnotation> annotations = const {},
    Set<MKPolyline> polylines = const {},
    Set<MKPolygon> polygons = const {},
    Set<MKCircle> circles = const {},
    MKMapConfiguration preferredConfiguration =
        const MKStandardMapConfiguration(),
    bool isZoomEnabled = true,
    bool showsUserLocation = false,
    MKCameraZoomRange cameraZoomRange = const MKCameraZoomRange(),
    void Function(MKMapViewController)? onMapCreated,
    void Function(CLLocationCoordinate2D)? onTap,
    ValueChanged<String>? onDidFailLoadingMap,
    ValueChanged<String>? onDidFailToLocateUser,
  }) {
    return MKMapView(
      initialCamera: sampleCamera,
      annotations: annotations,
      polylines: polylines,
      polygons: polygons,
      circles: circles,
      preferredConfiguration: preferredConfiguration,
      isZoomEnabled: isZoomEnabled,
      showsUserLocation: showsUserLocation,
      cameraZoomRange: cameraZoomRange,
      onMapCreated: onMapCreated,
      onTap: onTap,
      onDidFailLoadingMap: onDidFailLoadingMap,
      onDidFailToLocateUser: onDidFailToLocateUser,
      debugControllerFactory: controllerFactory,
    );
  }

  group('platform guard', () {
    testWidgets(
      'throws MapKitUnsupportedPlatformException off Apple platforms',
      (tester) async {
        await tester.pumpWidget(const MKMapView(initialCamera: sampleCamera));
        check(tester.takeException()).isA<MapKitUnsupportedPlatformException>();
      },
    );
  });

  group('initialize', () {
    testWidgets('pushes camera, configuration, and content once', (
      tester,
    ) async {
      MKMapViewController? created;
      await tester.pumpWidget(
        map(
          annotations: {annotation('a')},
          polylines: {polyline('p')},
          onMapCreated: (c) => created = c,
        ),
      );
      await tester.pump();

      check(created).isNotNull();
      check(host.callNames).deepEquals(['initialize']);
      final params = host.initializeParams;
      check(params.initialCamera.distance).equals(sampleCamera.distance);
      check(params.annotations).length.equals(1);
      check(params.polylines).length.equals(1);
      check(params.polygons).isEmpty();
    });

    testWidgets('assembles MKMapView defaults onto the wire', (tester) async {
      await tester.pumpWidget(map());
      await tester.pump();

      final config = host.initializeParams.configuration;
      check(config.kind).equals(PlatformMapKind.standard);
      check(config.emphasisStyle).equals(MKMapEmphasisStyle.standard);
      check(config.elevationStyle).equals(MKMapElevationStyle.flat);
      check(config.isZoomEnabled).isTrue();
      check(config.isScrollEnabled).isTrue();
      check(config.showsCompass).isTrue();
      check(config.showsScale).isFalse();
      check(config.showsUserLocation).isFalse();
      check(config.showsUserTrackingButton).isFalse();
      check(config.userTrackingMode).equals(MKUserTrackingMode.none);
      check(config.selectableMapFeatures).isEmpty();
      check(config.pointOfInterestFilter).isNotNull();
      check(config.pointOfInterestFilter!.mode).equals(PlatformPOIMode.all);
      check(config.cameraZoomRange).isNotNull();
      check(config.cameraZoomRange!.minCenterCoordinateDistance).isNull();
      check(config.cameraBoundary).isNull();
    });

    testWidgets('flattens hybrid and imagery configurations', (tester) async {
      await tester.pumpWidget(
        map(
          preferredConfiguration: const MKHybridMapConfiguration(
            showsTraffic: true,
            pointOfInterestFilter: .excludingAll,
          ),
        ),
      );
      await tester.pump();

      final config = host.initializeParams.configuration;
      check(config.kind).equals(PlatformMapKind.hybrid);
      check(config.showsTraffic).isTrue();
      check(config.pointOfInterestFilter!.mode).equals(PlatformPOIMode.none);
    });
  });

  group('didUpdateWidget', () {
    testWidgets('diffs annotation sets into update calls', (tester) async {
      await tester.pumpWidget(map(annotations: {annotation('a')}));
      await tester.pump();

      await tester.pumpWidget(
        map(
          annotations: {
            annotation('a', coordinate: infiniteLoop),
            annotation('b'),
          },
        ),
      );
      await tester.pump();

      host.expectCalls(['initialize', 'updateAnnotations']);
      final (toAdd, toChange, idsToRemove) = host.calls
          .expectLastArgs<AnnotationUpdate>('updateAnnotations');
      check(toAdd).length.equals(1);
      check(toAdd.single.id).equals('b');
      check(toChange).length.equals(1);
      check(toChange.single.id).equals('a');
      check(idsToRemove).isEmpty();
    });

    testWidgets('an icon-only restyle routes to toChange with the new tint', (
      tester,
    ) async {
      MKPointAnnotation marker(Color tint) => MKPointAnnotation(
        id: const MKAnnotationId('a'),
        coordinate: applePark,
        icon: MKAnnotationIcon.marker(markerTintColor: tint),
      );

      await tester.pumpWidget(
        map(annotations: {marker(const Color(0xFF3F51B5))}),
      );
      await tester.pump();

      // Same id and coordinate; only the marker tint changes — the in-place
      // update path the 0.2.2 marker-restyle fix depends on.
      await tester.pumpWidget(
        map(annotations: {marker(const Color(0xFFFF5722))}),
      );
      await tester.pump();

      host.expectCalls(['initialize', 'updateAnnotations']);
      final (toAdd, toChange, idsToRemove) = host.calls
          .expectLastArgs<AnnotationUpdate>('updateAnnotations');
      check(toAdd).isEmpty();
      check(idsToRemove).isEmpty();
      check(toChange).length.equals(1);
      check(toChange.single.id).equals('a');
      check(toChange.single.icon.markerTintArgb).equals(0xFFFF5722);
    });

    testWidgets('routes each overlay kind to its own update call', (
      tester,
    ) async {
      await tester.pumpWidget(map(polylines: {polyline('p')}));
      await tester.pump();

      await tester.pumpWidget(
        map(polylines: {}, polygons: {polygon('g')}, circles: {circle('c')}),
      );
      await tester.pump();

      host.expectCalls([
        'initialize',
        'updatePolylines',
        'updatePolygons',
        'updateCircles',
      ]);
      final (_, _, removedPolylines) = host.calls.requireArgsAt<PolylineUpdate>(
        1,
      );
      check(removedPolylines).deepEquals(['p']);
    });

    testWidgets('pushes one configuration update when a view prop changes', (
      tester,
    ) async {
      await tester.pumpWidget(map());
      await tester.pump();

      await tester.pumpWidget(
        map(
          isZoomEnabled: false,
          showsUserLocation: true,
          cameraZoomRange: const MKCameraZoomRange(
            minCenterCoordinateDistance: 500,
          ),
        ),
      );
      await tester.pump();

      host.expectCalls(['initialize', 'updateMapConfiguration']);
      final config = host.calls.expectLastArgs<PlatformMapConfiguration>(
        'updateMapConfiguration',
      );
      check(config.isZoomEnabled).isFalse();
      check(config.showsUserLocation).isTrue();
      check(config.cameraZoomRange!.minCenterCoordinateDistance).equals(500);
    });

    testWidgets('pushes a configuration update when the base style changes', (
      tester,
    ) async {
      await tester.pumpWidget(map());
      await tester.pump();

      await tester.pumpWidget(
        map(preferredConfiguration: const MKImageryMapConfiguration()),
      );
      await tester.pump();

      final config = host.calls.expectLastArgs<PlatformMapConfiguration>(
        'updateMapConfiguration',
      );
      check(config.kind).equals(PlatformMapKind.imagery);
      check(config.pointOfInterestFilter).isNull();
    });

    testWidgets('identical rebuild sends nothing', (tester) async {
      await tester.pumpWidget(map(annotations: {annotation('a')}));
      await tester.pump();

      await tester.pumpWidget(map(annotations: {annotation('a')}));
      await tester.pump();

      check(host.callNames).deepEquals(['initialize']);
    });
  });

  group('inbound events', () {
    testWidgets('map taps reach the widget callback', (tester) async {
      MKMapViewController? controller;
      CLLocationCoordinate2D? tapped;
      await tester.pumpWidget(
        map(onMapCreated: (c) => controller = c, onTap: (c) => tapped = c),
      );
      await tester.pump();

      controller!.eventHandler.onMapTap(platformCoord(1, 2));
      check(
        tapped,
      ).equals(const CLLocationCoordinate2D(latitude: 1, longitude: 2));
    });

    testWidgets('annotation taps reach the matching annotation', (
      tester,
    ) async {
      MKMapViewController? controller;
      var tapCount = 0;
      final tappable = MKPointAnnotation(
        id: const MKAnnotationId('a'),
        coordinate: applePark,
        onTap: () => tapCount++,
      );
      await tester.pumpWidget(
        map(annotations: {tappable}, onMapCreated: (c) => controller = c),
      );
      await tester.pump();

      controller!.eventHandler
        ..onAnnotationTap('a')
        ..onAnnotationTap('missing');
      check(tapCount).equals(1);
    });

    testWidgets('failure events reach the widget callbacks', (tester) async {
      MKMapViewController? controller;
      String? loadError;
      String? locateError;
      await tester.pumpWidget(
        map(
          onMapCreated: (c) => controller = c,
          onDidFailLoadingMap: (e) => loadError = e,
          onDidFailToLocateUser: (e) => locateError = e,
        ),
      );
      await tester.pump();

      controller!.eventHandler
        ..onDidFailLoadingMap('offline')
        ..onDidFailToLocateUser('denied');
      check(loadError).equals('offline');
      check(locateError).equals('denied');
    });
  });
}
