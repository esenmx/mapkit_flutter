import 'package:flutter/material.dart';
import 'package:mapkit_flutter/mapkit_flutter.dart';

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
  static const _sanFrancisco = CLLocationCoordinate2D(
    latitude: 37.7749,
    longitude: -122.4194,
  );

  MKMapViewController? _controller;
  MKMapConfiguration _configuration = const MKStandardMapConfiguration();

  late final Set<MKPointAnnotation> _annotations = {
    const MKPointAnnotation(
      id: MKAnnotationId('apple-park'),
      coordinate: _applePark,
      title: 'Apple Park',
      subtitle: 'One Apple Park Way',
    ),
    const MKPointAnnotation(
      id: MKAnnotationId('infinite-loop'),
      coordinate: _infiniteLoop,
      icon: MKAnnotationIcon.marker(
        markerTintColor: Colors.indigo,
        systemImage: 'laptopcomputer',
      ),
      title: 'Infinite Loop',
      subtitle: 'Previous campus',
    ),
  };

  final Set<MKPolyline> _polylines = {
    const MKPolyline.geodesic(
      id: MKPolylineId('campus-to-sf'),
      coordinates: [_applePark, _sanFrancisco],
      lineWidth: 4,
      gradientColors: [Colors.blue, Colors.purple],
    ),
    const MKPolyline(
      id: MKPolylineId('campus-link'),
      coordinates: [_applePark, _infiniteLoop],
      strokeColor: Colors.teal,
      lineWidth: 3,
      lineDashPattern: [6, 4],
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
      interiorPolygons: [
        [
          CLLocationCoordinate2D(latitude: 37.3360, longitude: -122.0110),
          CLLocationCoordinate2D(latitude: 37.3360, longitude: -122.0075),
          CLLocationCoordinate2D(latitude: 37.3330, longitude: -122.0075),
          CLLocationCoordinate2D(latitude: 37.3330, longitude: -122.0110),
        ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _openLookAround() async {
    final opened = await _controller?.openLookAround(_applePark) ?? false;
    if (!mounted) return;
    if (!opened) {
      _showMessage('No Look Around scene for this coordinate.');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MapKit Flutter')),
      body: MKMapView(
        initialCamera: MKMapCamera.withZoomLevel(
          centerCoordinate: _applePark,
          zoomLevel: 14,
        ),
        preferredConfiguration: _configuration,
        annotations: _annotations,
        polylines: _polylines,
        polygons: _polygons,
        circles: _circles,
        onMapCreated: (controller) => _controller = controller,
        onTap: (coordinate) => _showMessage('tapped $coordinate'),
      ),
      floatingActionButton: Wrap(
        direction: Axis.vertical,
        spacing: 8,
        children: [
          FloatingActionButton.small(
            heroTag: 'standard',
            tooltip: 'Standard',
            onPressed: () => setState(() {
              _configuration = const MKStandardMapConfiguration();
            }),
            child: const Icon(Icons.map),
          ),
          FloatingActionButton.small(
            heroTag: 'hybrid',
            tooltip: 'Hybrid',
            onPressed: () => setState(() {
              _configuration = const MKHybridMapConfiguration();
            }),
            child: const Icon(Icons.layers),
          ),
          FloatingActionButton.small(
            heroTag: 'imagery',
            tooltip: 'Imagery',
            onPressed: () => setState(() {
              _configuration = const MKImageryMapConfiguration();
            }),
            child: const Icon(Icons.satellite_alt),
          ),
          FloatingActionButton.small(
            heroTag: 'fit',
            tooltip: 'Fit annotations',
            onPressed: () => _controller?.fitCoordinates(
              _annotations.map((a) => a.coordinate),
            ),
            child: const Icon(Icons.fit_screen),
          ),
          FloatingActionButton.small(
            heroTag: 'look-around',
            tooltip: 'Look Around',
            onPressed: _openLookAround,
            child: const Icon(Icons.streetview),
          ),
          FloatingActionButton.small(
            heroTag: 'snapshot',
            tooltip: 'Snapshot',
            onPressed: _showSnapshot,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
