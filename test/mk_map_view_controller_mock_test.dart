import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '_helpers/fixtures.dart';
import 'mk_map_view_controller_mock_test.mocks.dart';

/// Guards the test seam consumers rely on: [MKMapViewController] is an
/// interface, so map-driving code can be unit-tested against a mock without a
/// platform view. A regression here (sealing the type, or leaking an
/// unexported type into a signature) breaks every downstream mock, so the
/// generated mock below is the oracle — it only compiles while the public
/// surface stays implementable from outside the package.
@GenerateNiceMocks([MockSpec<MKMapViewController>()])
void main() {
  late MockMKMapViewController controller;

  // Nice mocks need a dummy for every non-nullable return type they hand back
  // before a stub is installed — including while `when(...)` runs.
  setUpAll(() => provideDummy<MKMapCamera>(sampleCamera));

  setUp(() => controller = MockMKMapViewController());

  test('mocked controller records imperative calls', () async {
    await controller.setCamera(sampleCamera, animated: false);
    verify(controller.setCamera(sampleCamera, animated: false)).called(1);
  });

  test('mocked camera feeds the CameraConveniences extension', () async {
    when(controller.camera).thenAnswer((_) async => sampleCamera);

    await controller.zoomIn();

    final zoomed =
        verify(controller.setCamera(captureAny, animated: anyNamed('animated')))
                .captured
                .single
            as MKMapCamera;
    check(zoomed.distance).equals(sampleCamera.distance / 2);
  });
}
