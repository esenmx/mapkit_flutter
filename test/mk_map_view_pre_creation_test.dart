// A rebuild that lands while the native platform view is still being created
// (before `onPlatformViewCreated`) must still refresh the id→callback dispatch
// tables: `initialize` pushes the *current* widget's annotations, so taps on
// them must reach the current closures, not the initState ones.
//
// Drives the real UiKitView creation lifecycle: platform_views `create` is held
// open on a Completer, the controller binds to a FakeHostApi on creation, and
// the native tap arrives through the controller's MapKitFlutterApi handler.
import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';

import '_helpers/fake_host_api.dart';
import '_helpers/fixtures.dart';

typedef _PreCreationRig = ({
  Completer<void> createGate,
  FakeHostApi host,
  Future<void> Function(String id) nativeTap,
});

void main() {
  _PreCreationRig installMocks(WidgetTester tester) {
    final createGate = Completer<void>();
    final host = FakeHostApi();
    MapKitFlutterApi? flutterApi;

    MKMapViewControllerImpl.debugPlatformHostFactory = (_, eventHandler) {
      flutterApi = eventHandler;
      return host;
    };
    addTearDown(() => MKMapViewControllerImpl.debugPlatformHostFactory = null);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        if (call.method == 'create') {
          await createGate.future;
        }
        return null;
      },
    );

    Future<void> nativeTap(String id) async {
      flutterApi?.onAnnotationSelect(id);
      await tester.pump();
    }

    return (createGate: createGate, host: host, nativeTap: nativeTap);
  }

  MKPointAnnotation ann(String id, VoidCallback onSelect) =>
      .new(id: .new(id), coordinate: applePark, onSelect: onSelect);

  Widget map(Set<MKPointAnnotation> annotations) => Directionality(
    textDirection: .ltr,
    child: MKMapView(initialCamera: sampleCamera, annotations: annotations),
  );

  testWidgets(
    'rebuild before platform-view creation: taps reach the current callbacks',
    (tester) async {
      final rig = installMocks(tester);
      final taps = <String>[];
      await tester.pumpWidget(map({ann('a', () => taps.add('a-old'))}));
      // Rebuild while `create` is still in flight.
      await tester.pumpWidget(
        map({ann('a', () => taps.add('a-new')), ann('b', () => taps.add('b'))}),
      );
      rig.createGate.complete();
      await tester.pumpAndSettle();
      check(rig.host.calls.map((c) => c.$1)).contains('initialize');

      await rig.nativeTap('b');
      await rig.nativeTap('a');
      check(taps).deepEquals(['b', 'a-new']);
    },
    variant: TargetPlatformVariant.only(.iOS),
  );

  testWidgets('control: the same rebuild after creation dispatches correctly', (
    tester,
  ) async {
    final rig = installMocks(tester);
    final taps = <String>[];
    await tester.pumpWidget(map({ann('a', () => taps.add('a-old'))}));
    rig.createGate.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      map({ann('a', () => taps.add('a-new')), ann('b', () => taps.add('b'))}),
    );
    await tester.pumpAndSettle();

    await rig.nativeTap('b');
    await rig.nativeTap('a');
    check(taps).deepEquals(['b', 'a-new']);
  }, variant: TargetPlatformVariant.only(.iOS));

  testWidgets('control: unmount before creation never wires a controller', (
    tester,
  ) async {
    final rig = installMocks(tester);
    var created = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: .ltr,
        child: MKMapView(
          initialCamera: sampleCamera,
          onMapCreated: (_) => created++,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    rig.createGate.complete();
    await tester.pumpAndSettle();
    check(created).equals(0);
    check(rig.host.calls).isEmpty();
  }, variant: TargetPlatformVariant.only(.iOS));
}
