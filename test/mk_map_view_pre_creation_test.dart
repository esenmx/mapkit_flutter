// A rebuild that lands while the native platform view is still being created
// (before `onPlatformViewCreated`) must still refresh the id→callback dispatch
// tables: `initialize` pushes the *current* widget's annotations, so taps on
// them must reach the current closures, not the initState ones.
//
// Drives the real UiKitView + Pigeon path: platform_views `create` is held
// open on a Completer, Pigeon host channels are answered with an empty
// success reply, and the native tap is injected on the FlutterApi channel.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';

import '_helpers/fixtures.dart';

const MessageCodec<Object?> _codec = MapKitHostApi.pigeonChannelCodec;
const _hostMethods = [
  'initialize',
  'updateAnnotations',
  'updatePolylines',
  'updatePolygons',
  'updateCircles',
  'updateMapConfiguration',
];

void main() {
  late Completer<void> createGate;
  late int viewId;
  late List<String> hostCalls;

  void installMocks(WidgetTester tester) {
    createGate = Completer<void>();
    hostCalls = [];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        viewId = (call.arguments as Map)['id'] as int;
        for (final m in _hostMethods) {
          messenger.setMockMessageHandler(
            'dev.flutter.pigeon.mapkit_flutter.MapKitHostApi.$m.$viewId',
            (data) async {
              hostCalls.add(m);
              return _codec.encodeMessage(<Object?>[null]);
            },
          );
        }
        await createGate.future;
      }
      return null;
    });
  }

  Future<void> nativeTap(WidgetTester tester, String id) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'dev.flutter.pigeon.mapkit_flutter.MapKitFlutterApi.onAnnotationTap.'
      '$viewId',
      _codec.encodeMessage(<Object?>[id]),
      (_) {},
    );
    await tester.pump();
  }

  MKPointAnnotation ann(String id, VoidCallback onTap) => MKPointAnnotation(
    id: MKAnnotationId(id),
    coordinate: applePark,
    onTap: onTap,
  );

  Widget map(Set<MKPointAnnotation> annotations) => Directionality(
    textDirection: TextDirection.ltr,
    child: MKMapView(initialCamera: sampleCamera, annotations: annotations),
  );

  testWidgets(
    'rebuild before platform-view creation: taps reach the current callbacks',
    (tester) async {
      installMocks(tester);
      final taps = <String>[];
      await tester.pumpWidget(map({ann('a', () => taps.add('a-old'))}));
      // Rebuild while `create` is still in flight.
      await tester.pumpWidget(
        map({ann('a', () => taps.add('a-new')), ann('b', () => taps.add('b'))}),
      );
      createGate.complete();
      await tester.pumpAndSettle();
      expect(hostCalls, contains('initialize'));

      await nativeTap(tester, 'b');
      await nativeTap(tester, 'a');
      expect(taps, ['b', 'a-new']);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('control: the same rebuild after creation dispatches correctly', (
    tester,
  ) async {
    installMocks(tester);
    final taps = <String>[];
    await tester.pumpWidget(map({ann('a', () => taps.add('a-old'))}));
    createGate.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      map({ann('a', () => taps.add('a-new')), ann('b', () => taps.add('b'))}),
    );
    await tester.pumpAndSettle();

    await nativeTap(tester, 'b');
    await nativeTap(tester, 'a');
    expect(taps, ['b', 'a-new']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('control: unmount before creation never wires a controller', (
    tester,
  ) async {
    installMocks(tester);
    var created = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MKMapView(
          initialCamera: sampleCamera,
          onMapCreated: (_) => created++,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    createGate.complete();
    await tester.pumpAndSettle();
    expect(created, 0);
    expect(hostCalls, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
