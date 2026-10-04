/// `copyWith` defaults meaning "argument omitted".
///
/// Each nullable `copyWith` parameter keeps its real type and defaults to the
/// sentinel of that type; `identical(x, keepX)` tells an omitted argument
/// (keep the field) from an explicit `null` (clear it). Top-level function
/// tear-offs and const literals are canonical, so no caller-built value is
/// identical to them.
library;

import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:meta/meta.dart';

/// Sentinel for `String?` parameters.
@internal
const String keepString = '\u0000mapkit_flutter.keep';

/// Sentinel for `List<double>?` parameters.
@internal
const List<double> keepDoubles = <double>[-1];

/// Sentinel for `VoidCallback?` parameters.
@internal
void keepCallback() {}

/// Sentinel for `ValueChanged<CLLocationCoordinate2D>?` parameters.
@internal
void keepCoordinateCallback(CLLocationCoordinate2D _) {}
