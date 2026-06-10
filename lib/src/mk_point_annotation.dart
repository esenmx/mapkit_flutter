import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'package:mapkit_flutter/src/cl_location_coordinate_2d.dart';
import 'package:mapkit_flutter/src/map_item_id.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_annotation_icon.dart';

typedef MKAnnotationId = MapItemId<MKPointAnnotation>;

/// A pin or custom marker at a geographical [coordinate], mirroring
/// `MKPointAnnotation` ([coordinate], [title], [subtitle]) with its
/// `MKAnnotationView` presentation merged in ([icon], [alpha], [isDraggable],
/// [zPriority]…) — Flutter is declarative, so there is no separate view
/// object to configure.
/// See: https://developer.apple.com/documentation/mapkit/mkpointannotation
@immutable
final class MKPointAnnotation {
  const MKPointAnnotation({
    required this.id,
    required this.coordinate,
    this.icon = const .marker(),
    this.title,
    this.subtitle,
    this.alpha = 1.0,
    this.anchorPoint = const Offset(0.5, 1),
    this.isDraggable = false,
    this.isHidden = false,
    this.zPriority = 500,
    this.clusteringIdentifier,
    this.onTap,
    this.onCalloutTap,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
  }) : assert(0.0 <= alpha && alpha <= 1.0, 'alpha must be in [0, 1]');

  final MKAnnotationId id;
  final CLLocationCoordinate2D coordinate;
  final MKAnnotationIcon icon;

  /// Callout title (`MKAnnotation.title`). A non-null title enables the
  /// callout bubble on tap.
  final String? title;

  /// Callout subtitle (`MKAnnotation.subtitle`).
  final String? subtitle;

  /// View opacity in `[0, 1]`.
  final double alpha;

  /// Normalized anchor within the icon image (`MKAnnotationView.anchorPoint`):
  /// `(0.5, 1)` pins the bottom-center to [coordinate]. Applies to
  /// [MKAnnotationIcon.image] icons; system markers anchor themselves.
  final Offset anchorPoint;

  /// Whether the user can drag the annotation
  /// (`MKAnnotationView.isDraggable`).
  final bool isDraggable;

  final bool isHidden;

  /// Display priority for overlap stacking
  /// (`MKAnnotationView.zPriority`); MapKit's default is 500
  /// (`.defaultUnselected`), higher floats above.
  final double zPriority;

  /// Annotations sharing the same `clusteringIdentifier` cluster together
  /// when they're close on screen (`MKAnnotationView.clusteringIdentifier`).
  /// `null` means the annotation never clusters.
  final String? clusteringIdentifier;

  final VoidCallback? onTap;
  final VoidCallback? onCalloutTap;
  final ValueChanged<CLLocationCoordinate2D>? onDragStart;
  final ValueChanged<CLLocationCoordinate2D>? onDrag;
  final ValueChanged<CLLocationCoordinate2D>? onDragEnd;

  MKPointAnnotation copyWith({
    CLLocationCoordinate2D? coordinate,
    MKAnnotationIcon? icon,
    String? title,
    String? subtitle,
    double? alpha,
    Offset? anchorPoint,
    bool? isDraggable,
    bool? isHidden,
    double? zPriority,
    String? clusteringIdentifier,
    VoidCallback? onTap,
    VoidCallback? onCalloutTap,
    ValueChanged<CLLocationCoordinate2D>? onDragStart,
    ValueChanged<CLLocationCoordinate2D>? onDrag,
    ValueChanged<CLLocationCoordinate2D>? onDragEnd,
  }) => MKPointAnnotation(
    id: id,
    coordinate: coordinate ?? this.coordinate,
    icon: icon ?? this.icon,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    alpha: alpha ?? this.alpha,
    anchorPoint: anchorPoint ?? this.anchorPoint,
    isDraggable: isDraggable ?? this.isDraggable,
    isHidden: isHidden ?? this.isHidden,
    zPriority: zPriority ?? this.zPriority,
    clusteringIdentifier: clusteringIdentifier ?? this.clusteringIdentifier,
    onTap: onTap ?? this.onTap,
    onCalloutTap: onCalloutTap ?? this.onCalloutTap,
    onDragStart: onDragStart ?? this.onDragStart,
    onDrag: onDrag ?? this.onDrag,
    onDragEnd: onDragEnd ?? this.onDragEnd,
  );

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
      other.clusteringIdentifier == clusteringIdentifier;

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
