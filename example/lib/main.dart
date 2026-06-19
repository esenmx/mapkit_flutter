import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

import 'custom_marker_widget.dart';
import 'restyle_lab.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'MapKit Flutter', home: HomePage());
  }
}

/// An interactive annotation **restyle lab**. A pin can be a native system
/// marker (`MKAnnotationIcon.marker`) or a completely custom Flutter widget
/// rasterized to an image (`MKAnnotationIcon.image`) — the bar at the bottom
/// flips the selected pin between the two and restyles it *in place* (same id,
/// new icon), the code path the 0.2.2 fix repairs.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _applePark = CLLocationCoordinate2D(
    latitude: 37.334922,
    longitude: -122.009033,
  );
  static const _infiniteLoop = CLLocationCoordinate2D(
    latitude: 37.331820,
    longitude: -122.030419,
  );
  static const _deAnza = CLLocationCoordinate2D(
    latitude: 37.319870,
    longitude: -122.045400,
  );
  static const _mainStreet = CLLocationCoordinate2D(
    latitude: 37.323200,
    longitude: -122.031900,
  );
  static const _sanFrancisco = CLLocationCoordinate2D(
    latitude: 37.7749,
    longitude: -122.4194,
  );

  static const _pins = <(MKAnnotationId, CLLocationCoordinate2D, String)>[
    (MKAnnotationId('apple-park'), _applePark, 'Apple Park'),
    (MKAnnotationId('infinite-loop'), _infiniteLoop, 'Infinite Loop'),
    (MKAnnotationId('de-anza'), _deAnza, 'De Anza'),
    (MKAnnotationId('main-street'), _mainStreet, 'Main Street'),
  ];

  MKMapViewController? _controller;
  MKMapConfiguration _configuration = const MKStandardMapConfiguration();

  // Per-pin styling, mutated in place. A non-null custom image makes the pin a
  // custom Flutter-widget marker; otherwise it is a native system marker.
  final Map<MKAnnotationId, PinStyle> _styles = {
    const MKAnnotationId('apple-park'): const PinStyle(
      tint: Color(0xFF3F51B5),
      glyph: 'building.2.fill',
    ),
    const MKAnnotationId('infinite-loop'): const PinStyle(
      tint: Color(0xFF009688),
      glyph: 'laptopcomputer',
    ),
    const MKAnnotationId('de-anza'): const PinStyle(
      tint: Color(0xFFFF9800),
      glyph: 'graduationcap.fill',
    ),
  };
  final Map<MKAnnotationId, Uint8List> _customImages = {};

  // Defaults to a pin so the bar is usable immediately; tapping empty map
  // clears it to null.
  MKAnnotationId? _selectedId = _pins.first.$1;

  // Off-screen host used to rasterize a Flutter widget into a marker image.
  final GlobalKey _captureKey = GlobalKey();
  Widget? _captureChild;

  bool _suppressed = false;

  final Set<MKPolyline> _polylines = {
    const MKPolyline.geodesic(
      id: MKPolylineId('campus-to-sf'),
      coordinates: [_applePark, _sanFrancisco],
      lineWidth: 4,
      gradientColors: [Colors.blue, Colors.purple],
    ),
  };

  final Set<MKPolygon> _polygons = {
    const MKPolygon(
      id: MKPolygonId('campus-zone'),
      coordinates: [
        CLLocationCoordinate2D(latitude: 37.3380, longitude: -122.0150),
        CLLocationCoordinate2D(latitude: 37.3380, longitude: -122.0035),
        CLLocationCoordinate2D(latitude: 37.3310, longitude: -122.0035),
        CLLocationCoordinate2D(latitude: 37.3310, longitude: -122.0150),
      ],
      fillColor: Color(0x2200AA00),
      strokeColor: Colors.green,
      lineWidth: 2,
    ),
  };

  final Set<MKCircle> _circles = {
    const MKCircle(
      id: MKCircleId('loop-radius'),
      center: _infiniteLoop,
      radius: 250,
      fillColor: Color(0x22FF8800),
      strokeColor: Colors.orange,
      lineWidth: 2,
    ),
  };

  @override
  void initState() {
    super.initState();
    // Show one custom Flutter-widget marker from the start, alongside the
    // native markers, so both kinds are visible on launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCustomMarker(const MKAnnotationId('main-street'), 'Main St');
    });
  }

  PinStyle _styleOf(MKAnnotationId id) => _styles[id] ?? const PinStyle();

  String _titleOf(MKAnnotationId id) => _pins.firstWhere((p) => p.$1 == id).$3;

  Set<MKPointAnnotation> get _annotations {
    if (_suppressed) return const {};
    return {for (final (id, coord, title) in _pins) _build(id, coord, title)};
  }

  MKPointAnnotation _build(
    MKAnnotationId id,
    CLLocationCoordinate2D coordinate,
    String title,
  ) {
    final style = _styleOf(id);
    final customImage = _customImages[id];
    final icon = customImage != null
        ? MKAnnotationIcon.image(customImage)
        : MKAnnotationIcon.marker(
            markerTintColor: style.tint,
            systemImage: style.glyph,
          );
    return MKPointAnnotation(
      id: id,
      coordinate: coordinate,
      icon: icon,
      // A custom image is centred on the coordinate; system markers anchor
      // themselves, so the value is ignored for them.
      anchorPoint: customImage != null
          ? const Offset(0.5, 0.5)
          : const Offset(0.5, 1),
      title: title,
      subtitle: style.subtitle,
      onTap: () => _select(id),
    );
  }

  // ------------------------- Selection -------------------------

  void _select(MKAnnotationId id) {
    setState(() => _selectedId = id);
    _controller?.showCallout(id);
  }

  void _selectNext() {
    final i = _pins.indexWhere((p) => p.$1 == _selectedId);
    _select(_pins[(i + 1) % _pins.length].$1);
  }

  /// Tapping empty map deselects. A pin tap also fires this callback, so ignore
  /// taps that land on a pin's screen target — robust to callback ordering.
  Future<void> _handleMapTap(CLLocationCoordinate2D coordinate) async {
    final controller = _controller;
    if (controller == null) return;
    final tapPoint = await controller.convertToPoint(coordinate);
    if (tapPoint == null) return;
    for (final (_, pinCoord, _) in _pins) {
      final pinPoint = await controller.convertToPoint(pinCoord);
      if (pinPoint != null && (pinPoint - tapPoint).distance < 44) return;
    }
    if (mounted && _selectedId != null) {
      setState(() => _selectedId = null);
    }
  }

  // ------------------------- Restyle actions -------------------------

  /// Restyle the selected marker. Restyling returns a custom-image pin to a
  /// native marker.
  void _restyle(PinStyle Function(PinStyle) transform) {
    final id = _selectedId;
    if (id == null) return _showMessage('Tap a pin to select it.');
    setState(() {
      _customImages.remove(id);
      _styles[id] = transform(_styleOf(id));
    });
  }

  void _cycleSubtitle() {
    final id = _selectedId;
    if (id == null) return _showMessage('Tap a pin to select it.');
    setState(() => _styles[id] = _styleOf(id).withNextSubtitle());
    _controller?.showCallout(id);
    _showMessage('Subtitle → ${_styleOf(id).subtitle ?? '(none)'}');
  }

  Future<void> _toggleCustomMarker() async {
    final id = _selectedId;
    if (id == null) return _showMessage('Tap a pin to select it.');
    if (_customImages.containsKey(id)) {
      setState(() => _customImages.remove(id));
      _showMessage('Native system marker');
      return;
    }
    await _setCustomMarker(id, _titleOf(id));
    if (mounted) _showMessage('Custom Flutter-widget marker');
  }

  /// Rasterize a Flutter widget and use it as [id]'s marker image.
  Future<void> _setCustomMarker(MKAnnotationId id, String label) async {
    final color = _styleOf(id).tint ?? Colors.deepPurple;
    final png = await _rasterize(
      customMarkerWidget(label: label, color: color),
    );
    if (png == null || !mounted) return;
    setState(() => _customImages[id] = png);
  }

  void _resetSelected() {
    final id = _selectedId;
    if (id == null) return _showMessage('Tap a pin to select it.');
    setState(() {
      _customImages.remove(id);
      _styles[id] = _styleOf(id).reset();
    });
    _showMessage('Reset to default marker');
  }

  /// Remove every annotation, then re-add them next frame so MapKit recycles
  /// pooled views — the reused pins must come back correctly styled.
  Future<void> _rebuildAll() async {
    setState(() => _suppressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _suppressed = false);
  }

  /// Paint [widget] off-screen and return its PNG bytes.
  Future<Uint8List?> _rasterize(Widget widget) async {
    setState(() => _captureChild = widget);
    await WidgetsBinding.instance.endOfFrame;
    final renderObject = _captureKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || !mounted) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = await renderObject.toImage(pixelRatio: dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (mounted) setState(() => _captureChild = null);
    return data?.buffer.asUint8List();
  }

  // ------------------------- Map controls -------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
  }

  /// Frame all pins with breathing room so edge markers aren't flush against
  /// the screen borders (the tight `containing` region gets inflated ~20%).
  void _fitAnnotations() {
    final region = MKCoordinateRegion.containing([
      for (final (_, coord, _) in _pins) coord,
    ]);
    if (region == null) return;
    _controller?.setRegion(
      MKCoordinateRegion(
        center: region.center,
        span: MKCoordinateSpan(
          latitudeDelta: region.span.latitudeDelta * 1.4,
          longitudeDelta: region.span.longitudeDelta * 1.4,
        ),
      ),
    );
  }

  Future<void> _openLookAround() async {
    final opened = await _controller?.openLookAround(_applePark) ?? false;
    if (!mounted) return;
    if (!opened) _showMessage('No Look Around scene for this coordinate.');
  }

  Future<void> _showSnapshot() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final bytes = await controller.takeSnapshot();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(child: Image.memory(bytes)),
      );
    } on MapKitException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  // ------------------------- UI -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapKit Flutter'),
        actions: [
          PopupMenuButton<MKMapConfiguration>(
            tooltip: 'Map style',
            icon: const Icon(Icons.map),
            onSelected: (config) => setState(() => _configuration = config),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: MKStandardMapConfiguration(),
                child: Text('Standard'),
              ),
              PopupMenuItem(
                value: MKHybridMapConfiguration(),
                child: Text('Hybrid'),
              ),
              PopupMenuItem(
                value: MKImageryMapConfiguration(),
                child: Text('Imagery'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Fit annotations',
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitAnnotations,
          ),
          IconButton(
            tooltip: 'Look Around',
            icon: const Icon(Icons.streetview),
            onPressed: _openLookAround,
          ),
          IconButton(
            tooltip: 'Snapshot',
            icon: const Icon(Icons.camera_alt),
            onPressed: _showSnapshot,
          ),
        ],
      ),
      body: Stack(
        children: [
          MKMapView(
            initialCamera: const MKMapCamera(
              centerCoordinate: CLLocationCoordinate2D(
                latitude: 37.3275,
                longitude: -122.0270,
              ),
              distance: 9000,
            ),
            preferredConfiguration: _configuration,
            annotations: _annotations,
            polylines: _polylines,
            polygons: _polygons,
            circles: _circles,
            onMapCreated: (controller) => _controller = controller,
            onTap: _handleMapTap,
          ),
          // Off-screen rasterization host for custom Flutter-widget markers.
          Positioned(
            left: -10000,
            top: -10000,
            child: RepaintBoundary(
              key: _captureKey,
              child: _captureChild ?? const SizedBox.shrink(),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom-in',
                  tooltip: 'Zoom in',
                  onPressed: () => _controller?.zoomIn(),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom-out',
                  tooltip: 'Zoom out',
                  onPressed: () => _controller?.zoomOut(),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _RestyleBar(
        selectedTitle: switch (_selectedId) {
          final id? => _titleOf(id),
          null => null,
        },
        isCustom: _customImages.containsKey(_selectedId),
        onSelectNext: _selectNext,
        onTint: () => _restyle((s) => s.withNextTint()),
        onGlyph: () => _restyle((s) => s.withNextGlyph()),
        onSubtitle: _cycleSubtitle,
        onCustom: _toggleCustomMarker,
        onReset: _resetSelected,
        onRebuild: _rebuildAll,
      ),
    );
  }
}

/// Bottom control bar acting on the currently selected pin.
class _RestyleBar extends StatelessWidget {
  const _RestyleBar({
    required this.selectedTitle,
    required this.isCustom,
    required this.onSelectNext,
    required this.onTint,
    required this.onGlyph,
    required this.onSubtitle,
    required this.onCustom,
    required this.onReset,
    required this.onRebuild,
  });

  final String? selectedTitle;
  final bool isCustom;
  final VoidCallback onSelectNext;
  final VoidCallback onTint;
  final VoidCallback onGlyph;
  final VoidCallback onSubtitle;
  final VoidCallback onCustom;
  final VoidCallback onReset;
  final VoidCallback onRebuild;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTitle == null
                        ? 'No pin selected — tap a pin'
                        : 'Selected: $selectedTitle'
                              '${isCustom ? '  ·  custom Flutter marker' : '  ·  native marker'}',
                    style: TextTheme.of(context).labelLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: onSelectNext,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: const Text('Next pin'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.palette, size: 18),
                  label: const Text('Tint'),
                  onPressed: onTint,
                ),
                ActionChip(
                  avatar: const Icon(Icons.emoji_symbols, size: 18),
                  label: const Text('Glyph'),
                  onPressed: onGlyph,
                ),
                ActionChip(
                  avatar: const Icon(Icons.notes, size: 18),
                  label: const Text('Subtitle'),
                  onPressed: onSubtitle,
                ),
                ActionChip(
                  avatar: Icon(
                    isCustom ? Icons.place : Icons.widgets,
                    size: 18,
                  ),
                  label: Text(isCustom ? 'Native' : 'Custom'),
                  onPressed: onCustom,
                ),
                ActionChip(
                  avatar: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset'),
                  onPressed: onReset,
                ),
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: const Text('Rebuild'),
                  onPressed: onRebuild,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
