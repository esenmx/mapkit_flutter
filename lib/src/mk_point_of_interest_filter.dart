import 'package:flutter/foundation.dart';
import 'package:mapkit_flutter/src/messages.g.dart';
import 'package:mapkit_flutter/src/mk_enums.dart';

/// Which points of interest (shops, transit, parks…) the base map labels,
/// mirroring `MKPointOfInterestFilter`: [includingAll], [excludingAll],
/// [MKPointOfInterestFilter.including], or [MKPointOfInterestFilter.excluding].
/// See: https://developer.apple.com/documentation/mapkit/mkpointofinterestfilter
@immutable
sealed class MKPointOfInterestFilter {
  const MKPointOfInterestFilter();

  /// Shows only the listed [categories].
  const factory MKPointOfInterestFilter.including(
    List<MKPointOfInterestCategory> categories,
  ) = IncludingPointsOfInterest;

  /// Shows every category except the listed [categories].
  const factory MKPointOfInterestFilter.excluding(
    List<MKPointOfInterestCategory> categories,
  ) = ExcludingPointsOfInterest;

  /// Shows every point-of-interest category.
  static const MKPointOfInterestFilter includingAll =
      IncludingAllPointsOfInterest();

  /// Hides all points of interest.
  static const MKPointOfInterestFilter excludingAll =
      ExcludingAllPointsOfInterest();

  @internal
  PlatformPointOfInterestFilter toPlatform();
}

/// Shows every point-of-interest category
/// ([MKPointOfInterestFilter.includingAll]).
final class IncludingAllPointsOfInterest extends MKPointOfInterestFilter {
  const IncludingAllPointsOfInterest();

  @override
  PlatformPointOfInterestFilter toPlatform() =>
      PlatformPointOfInterestFilter(mode: .all, categories: const []);

  @override
  bool operator ==(Object other) => other is IncludingAllPointsOfInterest;

  @override
  int get hashCode => 0;
}

/// Hides all points of interest ([MKPointOfInterestFilter.excludingAll]).
final class ExcludingAllPointsOfInterest extends MKPointOfInterestFilter {
  const ExcludingAllPointsOfInterest();

  @override
  PlatformPointOfInterestFilter toPlatform() =>
      PlatformPointOfInterestFilter(mode: .none, categories: const []);

  @override
  bool operator ==(Object other) => other is ExcludingAllPointsOfInterest;

  @override
  int get hashCode => 1;
}

/// Shows only the listed [categories].
final class IncludingPointsOfInterest extends MKPointOfInterestFilter {
  const IncludingPointsOfInterest(this.categories);

  final List<MKPointOfInterestCategory> categories;

  @override
  PlatformPointOfInterestFilter toPlatform() =>
      PlatformPointOfInterestFilter(mode: .including, categories: categories);

  @override
  bool operator ==(Object other) =>
      other is IncludingPointsOfInterest &&
      listEquals(other.categories, categories);

  @override
  int get hashCode => Object.hash('including', Object.hashAll(categories));
}

/// Shows every category except the listed [categories].
final class ExcludingPointsOfInterest extends MKPointOfInterestFilter {
  const ExcludingPointsOfInterest(this.categories);

  final List<MKPointOfInterestCategory> categories;

  @override
  PlatformPointOfInterestFilter toPlatform() =>
      PlatformPointOfInterestFilter(mode: .excluding, categories: categories);

  @override
  bool operator ==(Object other) =>
      other is ExcludingPointsOfInterest &&
      listEquals(other.categories, categories);

  @override
  int get hashCode => Object.hash('excluding', Object.hashAll(categories));
}
