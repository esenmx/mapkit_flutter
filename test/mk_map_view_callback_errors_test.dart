// A throwing callback must reach FlutterError rather than escaping the
// MapKitFlutterApi handler: an escaped throw would cross FFI back to the native
// sender (which can only log and drop it), so a callback exception would
// otherwise vanish from Flutter's error pipeline in every build mode.
import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';

import '_helpers/fake_host_api.dart';
import '_helpers/fixtures.dart';

void main() {
  void boom(String name) => throw StateError('boom:$name');

  Widget map() => Directionality(
    textDirection: .ltr,
    child: MKMapView(
      initialCamera: sampleCamera,
      showsUserLocation: true,
      selectableMapFeatures: const {.pointsOfInterest},
      annotations: {
        .new(
          id: const .new('a'),
          coordinate: applePark,
          title: 'title',
          isDraggable: true,
          calloutConsumesTapEvents: true,
          onSelect: () => boom('onAnnotationSelect'),
          onDeselect: () => boom('onAnnotationDeselect'),
          onDragStart: (_) => boom('onAnnotationDragStart'),
          onDragEnd: (_) => boom('onAnnotationDragEnd'),
          onCalloutTap: () => boom('onCalloutTap'),
        ),
      },
      polylines: {
        .new(
          id: const .new('l'),
          coordinates: [applePark, infiniteLoop],
          consumeTapEvents: true,
          onTap: () => boom('onPolylineTap'),
        ),
      },
      polygons: {
        .new(
          id: const .new('g'),
          coordinates: [applePark, infiniteLoop, sampleCamera.centerCoordinate],
          consumeTapEvents: true,
          onTap: () => boom('onPolygonTap'),
        ),
      },
      circles: {
        .new(
          id: const .new('c'),
          center: applePark,
          radius: 10,
          consumeTapEvents: true,
          onTap: () => boom('onCircleTap'),
        ),
      },
      onCameraMoveStarted: () => boom('onCameraMoveStarted'),
      onCameraMove: (_) => boom('onCameraMove'),
      onCameraIdle: () => boom('onCameraIdle'),
      onUserTrackingModeChanged: (_) => boom('onUserTrackingModeChanged'),
      onTap: (_) => boom('onMapTap'),
      onLongPress: (_) => boom('onMapLongPress'),
      onDidFailLoadingMap: (_) => boom('onDidFailLoadingMap'),
      onDidFailToLocateUser: (_) => boom('onDidFailToLocateUser'),
      onMapFeatureSelected: (_) => boom('onMapFeatureSelected'),
    ),
  );

  final coordinate = PlatformCoordinate(latitude: 1, longitude: 2);
  PlatformMapCamera camera({double distance = 100}) => .new(
    centerCoordinate: coordinate,
    distance: distance,
    heading: 0,
    pitch: 0,
  );

  late MapKitFlutterApi flutterApi;

  Future<void> mount(WidgetTester tester) async {
    MKMapViewControllerImpl.debugPlatformHostFactory = (_, eventHandler) {
      flutterApi = eventHandler;
      return FakeHostApi();
    };
    addTearDown(() => MKMapViewControllerImpl.debugPlatformHostFactory = null);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (_) async => null,
    );
    await tester.pumpWidget(map());
    await tester.pumpAndSettle();
  }

  final events = <String, void Function(MapKitFlutterApi)>{
    'onCameraMoveStarted': (api) => api.onCameraMoveStarted(),
    'onCameraMove': (api) => api.onCameraMove(camera()),
    'onCameraIdle': (api) => api.onCameraIdle(),
    'onUserTrackingModeChanged': (api) =>
        api.onUserTrackingModeChanged(.follow),
    'onAnnotationSelect': (api) => api.onAnnotationSelect('a'),
    'onAnnotationDeselect': (api) => api.onAnnotationDeselect('a'),
    'onMapFeatureSelected': (api) => api.onMapFeatureSelected(
      PlatformMapFeature(featureType: .territory, coordinate: coordinate),
    ),
    'onAnnotationDragStart': (api) =>
        api.onAnnotationDragStart('a', coordinate),
    'onAnnotationDragEnd': (api) => api.onAnnotationDragEnd('a', coordinate),
    'onCalloutTap': (api) => api.onCalloutTap('a'),
    'onPolylineTap': (api) => api.onPolylineTap('l'),
    'onPolygonTap': (api) => api.onPolygonTap('g'),
    'onCircleTap': (api) => api.onCircleTap('c'),
    'onMapTap': (api) => api.onMapTap(coordinate),
    'onMapLongPress': (api) => api.onMapLongPress(coordinate),
    'onDidFailLoadingMap': (api) => api.onDidFailLoadingMap('offline'),
    'onDidFailToLocateUser': (api) => api.onDidFailToLocateUser('denied'),
  };

  for (final MapEntry(key: method, value: invoke) in events.entries) {
    testWidgets('$method: a throw reaches FlutterError without rethrowing', (
      tester,
    ) async {
      await mount(tester);

      invoke(flutterApi);
      await tester.pump();

      check(tester.takeException())
          .isA<StateError>()
          .has('message', (e) => e.message)
          .equals('boom:$method');
    }, variant: TargetPlatformVariant.only(.iOS));
  }

  testWidgets('the details name the plugin and the callback', (tester) async {
    await mount(tester);
    final reported = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = original);

    flutterApi.onMapTap(coordinate);
    await tester.pump();
    FlutterError.onError = original;

    final details = reported.single;
    check(details.library).equals('mapkit_flutter');
    check(details.context.toString()).contains('onMapTap');
    check(details.stack.toString()).contains('boom');
  }, variant: TargetPlatformVariant.only(.iOS));

  testWidgets('a payload the models reject reaches FlutterError too', (
    tester,
  ) async {
    await mount(tester);

    flutterApi.onCameraMove(camera(distance: 0));
    await tester.pump();

    check(tester.takeException()).isA<ArgumentError>();
  }, variant: TargetPlatformVariant.only(.iOS));
}
