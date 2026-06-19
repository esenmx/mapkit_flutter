import 'package:flutter/material.dart';

/// A completely custom, Flutter-built marker: a rounded pill with an icon and
/// label. Rasterized off-screen to a PNG and handed to `MKAnnotationIcon.image`,
/// it proves any Flutter widget can back a map annotation — the counterpart to
/// the native `MKAnnotationIcon.marker` balloon.
///
/// The outer padding leaves room for the drop shadow so the `RepaintBoundary`
/// capture doesn't clip it.
Widget customMarkerWidget({required String label, required Color color}) {
  return Material(
    type: MaterialType.transparency,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
