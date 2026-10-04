import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_map_view_controller.dart';

import '_helpers/controller_harness.dart';
import '_helpers/fake_host_api.dart';
import '_helpers/fixtures.dart';
import '_helpers/recorded_call.dart';

void main() {
  const red = MKPolyline(
    id: MKPolylineId('route'),
    coordinates: [applePark, infiniteLoop],
    strokeColor: Color(0xFFFF0000),
  );
  const blue = MKPolyline(
    id: MKPolylineId('route'),
    coordinates: [applePark, infiniteLoop],
    strokeColor: Color(0xFF0000FF),
  );

  testWidgets('two objects of one kind sharing an id assert in debug', (
    tester,
  ) async {
    final host = FakeHostApi();
    await tester.pumpWidget(
      MKMapView(
        initialCamera: sampleCamera,
        polylines: {red, blue},
        debugControllerFactory: (sink) =>
            MKMapViewControllerImpl(viewId: 900, sink: sink, hostApi: host),
      ),
    );
    check(tester.takeException()).isA<AssertionError>();
  });

  test('initialize sends one object per id, last wins', () async {
    final harness = ControllerHarness();
    await harness.controller.initialize(
      initialCamera: sampleCamera,
      configuration: PlatformMapConfiguration(
        kind: .standard,
        emphasisStyle: .standard,
        elevationStyle: .flat,
        showsTraffic: false,
        showsCompass: true,
        showsScale: false,
        showsUserLocation: false,
        showsUserTrackingButton: false,
        userTrackingMode: .none,
        insetsLayoutMarginsFromSafeArea: true,
        isRotateEnabled: true,
        isScrollEnabled: true,
        isZoomEnabled: true,
        isPitchEnabled: true,
        selectableMapFeatures: [],
      ),
      annotations: const {},
      polylines: {red, blue},
      polygons: const {},
      circles: const {},
    );
    final polylines = harness.host.initializeParams.polylines;
    check(polylines).length.equals(1);
    check(polylines.single.strokeColorArgb).equals(0xFF0000FF);
  });
}
