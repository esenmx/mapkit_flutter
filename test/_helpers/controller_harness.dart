import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import 'fake_host_api.dart';
import 'recorded_call.dart';
import 'recording_sink.dart';

/// Bundles a [FakeHostApi], [RecordingSink], and [MKMapViewController] for
/// outbound/inbound channel tests.
final class ControllerHarness {
  ControllerHarness({this.viewId = 1, RecordingSink? sink})
    : sink = sink ?? RecordingSink(),
      host = FakeHostApi();

  final int viewId;
  final RecordingSink sink;
  final FakeHostApi host;

  late final MKMapViewController controller = MKMapViewController.create(
    viewId: viewId,
    sink: sink,
    hostApi: host,
  );

  Future<void> dispose() => controller.dispose();

  void expectCalls(List<String> names) => host.expectCalls(names);

  CameraCall expectSetCamera() =>
      host.calls.expectLastArgs<CameraCall>('setCamera');

  CoordinateCall expectSetCenter() =>
      host.calls.expectLastArgs<CoordinateCall>('setCenter');

  RegionCall expectSetRegion() =>
      host.calls.expectLastArgs<RegionCall>('setRegion');

  void expectLastCall(String name) =>
      check(host.calls.lastRecorded.name).equals(name);

  T expectLast<T>(String name) => host.calls.expectLastArgs<T>(name);

  T expectSink<T>(String event) =>
      sink.events.requireSinglePayload<T>(event: event);

  List<String> get eventNames => [for (final e in sink.events) e.$1];
}

/// Runs [action] and returns the caught [MapKitException] subtype.
Future<T> catchMapKit<T extends MapKitException>(
  Future<void> Function() action,
) async {
  try {
    await action();
  } on T catch (error) {
    return error;
  } catch (error) {
    fail('Expected $T, got ${error.runtimeType}: $error');
  }
  fail('Expected $T');
}
