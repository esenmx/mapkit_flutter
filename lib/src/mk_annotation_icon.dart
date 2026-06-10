import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'package:mapkit_flutter/src/messages.g.dart';

/// What an annotation looks like, mirroring the `MKMarkerAnnotationView` /
/// `MKAnnotationView` split: [MKAnnotationIcon.marker] is the system balloon
/// marker with optional `markerTintColor` / glyph branding, and
/// [MKAnnotationIcon.image] supplies fully custom imagery
/// (`MKAnnotationView.image`).
/// See: https://developer.apple.com/documentation/mapkit/mkmarkerannotationview
@immutable
final class MKAnnotationIcon {
  /// System balloon marker (`MKMarkerAnnotationView`).
  ///
  /// All-default renders the plain red marker. [markerTintColor] tints the
  /// balloon; brand the glyph with a short [glyphText] label or an SF Symbol
  /// via [systemImage], tinted by [glyphTintColor].
  const MKAnnotationIcon.marker({
    Color? markerTintColor,
    String? glyphText,
    String? systemImage,
    Color? glyphTintColor,
  }) : _type = .marker,
       _markerTintColor = markerTintColor,
       _glyphText = glyphText,
       _glyphSystemImage = systemImage,
       _glyphTintColor = glyphTintColor,
       _imageBytes = null;

  /// Raw PNG bytes as the annotation image (`MKAnnotationView.image`). Render
  /// any Flutter widget to a PNG (e.g. via `RenderRepaintBoundary.toImage`)
  /// and pass it here for a fully custom marker.
  const MKAnnotationIcon.image(Uint8List png)
    : _type = .image,
      _markerTintColor = null,
      _glyphText = null,
      _glyphSystemImage = null,
      _glyphTintColor = null,
      _imageBytes = png;

  /// Load an annotation image from the asset bundle into an
  /// [MKAnnotationIcon.image].
  static Future<MKAnnotationIcon> asset(
    String name, {
    AssetBundle? bundle,
    String? package,
    double? devicePixelRatio,
  }) async {
    final config = ImageConfiguration(
      devicePixelRatio:
          devicePixelRatio ??
          PlatformDispatcher.instance.implicitView?.devicePixelRatio ??
          1.0,
    );
    final provider = AssetImage(name, bundle: bundle, package: package);
    final key = await provider.obtainKey(config);
    final data = await (bundle ?? rootBundle).load(key.name);
    return .image(data.buffer.asUint8List());
  }

  final PlatformAnnotationIconType _type;
  final Color? _markerTintColor;
  final String? _glyphText;
  final String? _glyphSystemImage;
  final Color? _glyphTintColor;
  final Uint8List? _imageBytes;

  @internal
  PlatformAnnotationIcon toPlatform() => PlatformAnnotationIcon(
    type: _type,
    markerTintArgb: _markerTintColor?.toARGB32(),
    glyphText: _glyphText,
    glyphSystemImage: _glyphSystemImage,
    glyphTintArgb: _glyphTintColor?.toARGB32(),
    imageBytes: _imageBytes,
  );

  @override
  bool operator ==(Object other) =>
      other is MKAnnotationIcon &&
      other._type == _type &&
      other._markerTintColor == _markerTintColor &&
      other._glyphText == _glyphText &&
      other._glyphSystemImage == _glyphSystemImage &&
      other._glyphTintColor == _glyphTintColor &&
      listEquals(other._imageBytes, _imageBytes);

  @override
  int get hashCode => Object.hash(
    _type,
    _markerTintColor,
    _glyphText,
    _glyphSystemImage,
    _glyphTintColor,
    _imageBytes == null ? null : Object.hashAll(_imageBytes),
  );

  @override
  String toString() {
    final b = StringBuffer('MKAnnotationIcon(')..write(_type.name);
    if (_markerTintColor case final c?) b.write(', markerTintColor: $c');
    if (_glyphText case final t?) b.write(', glyphText: $t');
    if (_glyphSystemImage case final s?) b.write(', systemImage: $s');
    if (_glyphTintColor case final c?) b.write(', glyphTintColor: $c');
    if (_imageBytes case final bytes?) b.write(', image: ${bytes.length}B');
    return (b..write(')')).toString();
  }
}
