import 'package:meta/meta.dart';

/// Computes the add/change/remove delta between two snapshots of map objects,
/// keyed by a stable string id. Shared by annotations and every overlay type so
/// the diff lives in one place instead of one near-identical class per kind.
@internal
final class MapObjectUpdates<T extends Object> {
  MapObjectUpdates.between(
    Set<T> before,
    Set<T> after, {
    required String Function(T) idOf,
  }) {
    final beforeById = {for (final o in before) idOf(o): o};
    final afterById = {for (final o in after) idOf(o): o};

    toAdd = {
      for (final e in afterById.entries)
        if (!beforeById.containsKey(e.key)) e.value,
    };
    toChange = {
      for (final e in afterById.entries)
        if (beforeById[e.key] case final prior? when prior != e.value) e.value,
    };
    idsToRemove = {
      for (final id in beforeById.keys)
        if (!afterById.containsKey(id)) id,
    };
  }

  late final Set<T> toAdd;
  late final Set<T> toChange;
  late final Set<String> idsToRemove;
}
