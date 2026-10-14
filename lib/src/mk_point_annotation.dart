import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'package:mapkit_flutter/src/_internal/copy_with_keep.dart';
import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/map_item_id.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_annotation_icon.dart';

/// Typed identifier for an [MKPointAnnotation].
typedef MKAnnotationId = MapItemId<MKPointAnnotation>;

/// A pin or custom marker at a geographical [coordinate], mirroring
/// `MKPointAnnotation` ([coordinate], [title], [subtitle]) with its
/// `MKAnnotationView` presentation merged in ([icon], [alpha], [isDraggable],
/// [zPriority]…) — Flutter is declarative, so there is no separate view
/// object to configure.
/// See: https://developer.apple.com/documentation/mapkit/mkpointannotation
@immutable
final class const MKPointAnnotation({
  /// Unique identifier used to diff this annotation across rebuilds.
  required final MKAnnotationId id,

  /// Geographical position of the annotation.
  required final CLLocationCoordinate2D coordinate,

  /// Visual appearance of the annotation view.
  final MKAnnotationIcon icon = const .marker(),

  /// Callout title (`MKAnnotation.title`). A non-null title enables the
  /// callout bubble on tap.
  final String? title,

  /// Callout subtitle (`MKAnnotation.subtitle`).
  final String? subtitle,

  /// View opacity in `[0, 1]`.
  final double alpha = 1.0,

  /// Normalized anchor within the icon image (`MKAnnotationView.anchorPoint`):
  /// `(0.5, 1)` pins the bottom-center to [coordinate]. Applies to
  /// [MKAnnotationIcon.image] icons; system markers anchor themselves. iOS
  /// only: macOS centers the image on [coordinate].
  final Offset anchorPoint = const Offset(0.5, 1),

  /// Whether the user can drag the annotation
  /// (`MKAnnotationView.isDraggable`).
  final bool isDraggable = false,

  /// Whether the annotation view is hidden on the map.
  final bool isHidden = false,

  /// Display priority for overlap stacking
  /// (`MKAnnotationView.zPriority`); MapKit's default is 500
  /// (`.defaultUnselected`), higher floats above.
  final double zPriority = 500,

  /// Annotations sharing the same `clusteringIdentifier` cluster together
  /// when they're close on screen (`MKAnnotationView.clusteringIdentifier`).
  /// `null` means the annotation never clusters.
  final String? clusteringIdentifier,

  /// Called when the user taps the annotation view.
  final VoidCallback? onTap,

  /// Called when the callout bubble is tapped. iOS only (macOS shows
  /// MapKit's default callout).
  final VoidCallback? onCalloutTap,

  /// Called with the starting coordinate when a drag begins.
  final ValueChanged<CLLocationCoordinate2D>? onDragStart,

  /// Called with the live coordinate while dragging.
  final ValueChanged<CLLocationCoordinate2D>? onDrag,

  /// Called with the final coordinate when a drag ends.
  final ValueChanged<CLLocationCoordinate2D>? onDragEnd,

  /// `mapView(_:didSelect:)` — user or programmatic, after `onTap`.
  final VoidCallback? onSelect,

  /// `mapView(_:didDeselect:)`.
  final VoidCallback? onDeselect,
}) {
  /// Creates a point annotation at [coordinate].
  this : assert(0.0 <= alpha && alpha <= 1.0, 'alpha must be in [0, 1]');

  /// Returns a copy with the given fields replaced.
  MKPointAnnotation copyWith({
    CLLocationCoordinate2D? coordinate,
    MKAnnotationIcon? icon,
    String? title = keepString,
    String? subtitle = keepString,
    double? alpha,
    Offset? anchorPoint,
    bool? isDraggable,
    bool? isHidden,
    double? zPriority,
    String? clusteringIdentifier = keepString,
    VoidCallback? onTap = keepCallback,
    VoidCallback? onCalloutTap = keepCallback,
    ValueChanged<CLLocationCoordinate2D>? onDragStart = keepCoordinateCallback,
    ValueChanged<CLLocationCoordinate2D>? onDrag = keepCoordinateCallback,
    ValueChanged<CLLocationCoordinate2D>? onDragEnd = keepCoordinateCallback,
    VoidCallback? onSelect = keepCallback,
    VoidCallback? onDeselect = keepCallback,
  }) => MKPointAnnotation(
    id: id,
    coordinate: coordinate ?? this.coordinate,
    icon: icon ?? this.icon,
    title: identical(title, keepString) ? this.title : title,
    subtitle: identical(subtitle, keepString) ? this.subtitle : subtitle,
    alpha: alpha ?? this.alpha,
    anchorPoint: anchorPoint ?? this.anchorPoint,
    isDraggable: isDraggable ?? this.isDraggable,
    isHidden: isHidden ?? this.isHidden,
    zPriority: zPriority ?? this.zPriority,
    clusteringIdentifier: identical(clusteringIdentifier, keepString)
        ? this.clusteringIdentifier
        : clusteringIdentifier,
    onTap: identical(onTap, keepCallback) ? this.onTap : onTap,
    onCalloutTap: identical(onCalloutTap, keepCallback)
        ? this.onCalloutTap
        : onCalloutTap,
    onDragStart: identical(onDragStart, keepCoordinateCallback)
        ? this.onDragStart
        : onDragStart,
    onDrag: identical(onDrag, keepCoordinateCallback) ? this.onDrag : onDrag,
    onDragEnd: identical(onDragEnd, keepCoordinateCallback)
        ? this.onDragEnd
        : onDragEnd,
    onSelect: identical(onSelect, keepCallback) ? this.onSelect : onSelect,
    onDeselect: identical(onDeselect, keepCallback)
        ? this.onDeselect
        : onDeselect,
  );

  /// Converts this annotation to its Pigeon wire representation.
  @internal
  PlatformAnnotation toPlatform() => PlatformAnnotation(
    id: id.value,
    coordinate: coordinate.toPlatform(),
    icon: icon.toPlatform(),
    title: title,
    subtitle: subtitle,
    calloutConsumesTapEvents: onCalloutTap != null,
    alpha: alpha,
    anchorPointX: anchorPoint.dx,
    anchorPointY: anchorPoint.dy,
    isDraggable: isDraggable,
    isHidden: isHidden,
    zPriority: zPriority,
    clusteringIdentifier: clusteringIdentifier,
  );

  @override
  bool operator ==(Object other) =>
      other is MKPointAnnotation &&
      other.id == id &&
      other.coordinate == coordinate &&
      other.icon == icon &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.alpha == alpha &&
      other.anchorPoint == anchorPoint &&
      other.isDraggable == isDraggable &&
      other.isHidden == isHidden &&
      other.zPriority == zPriority &&
      other.clusteringIdentifier == clusteringIdentifier &&
      // `onCalloutTap`'s presence drives the native `calloutConsumesTapEvents`
      // flag, so a null↔non-null toggle is a real change. Closure identity
      // still isn't compared — that routes through the live dispatch table.
      (other.onCalloutTap != null) == (onCalloutTap != null);

  @override
  int get hashCode => Object.hash(
    id,
    coordinate,
    icon,
    title,
    subtitle,
    alpha,
    anchorPoint,
    isDraggable,
    isHidden,
    zPriority,
    clusteringIdentifier,
    onCalloutTap != null,
  );

  @override
  String toString() {
    final b = StringBuffer('MKPointAnnotation(')
      ..write('id: ${id.value}, ')
      ..write('coordinate: $coordinate, ')
      ..write('title: $title, ')
      ..write('isHidden: $isHidden, ')
      ..write('isDraggable: $isDraggable, ')
      ..write('onTap: ${onTap != null ? 'set' : 'null'}');
    return (b..write(')')).toString();
  }
}
