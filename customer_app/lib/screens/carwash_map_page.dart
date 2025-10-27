import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'carwash_services.dart';
import '../models/booking.dart';

class CarwashMapPage extends StatefulWidget {
  final List<Map<String, dynamic>> carwashes;
  final List<Map<String, dynamic>> cart;
  final List<Booking> bookings;

  const CarwashMapPage({
    super.key,
    required this.carwashes,
    required this.cart,
    required this.bookings,
  });

  @override
  State<CarwashMapPage> createState() => _CarwashMapPageState();
}

class _CarwashMapPageState extends State<CarwashMapPage> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services.")),
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? pos;
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      setState(() {
        if (pos != null) {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        }
      });

      _addCarwashMarkers();
    } catch (e) {
      _addCarwashMarkers();
      debugPrint("Map init error: $e");
    }
  }

  void _addCarwashMarkers() {
    final newMarkers = widget.carwashes.map<Marker>((carwash) {
      final lat = (carwash['latitude'] is num)
          ? (carwash['latitude'] as num).toDouble()
          : double.tryParse(carwash['latitude']?.toString() ?? '') ?? 0.0;
      final lon = (carwash['longitude'] is num)
          ? (carwash['longitude'] as num).toDouble()
          : double.tryParse(carwash['longitude']?.toString() ?? '') ?? 0.0;

      final carwashId = carwash['id'] is int
          ? carwash['id']
          : int.tryParse(carwash['id'].toString()) ?? 0;

      final name = carwash['name'] ?? "Unnamed Carwash";

      return Marker(
        point: LatLng(lat, lon),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () {
            _showCarwashInfo(name, carwashId);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_car_wash, color: Colors.blueAccent, size: 35),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          point: _currentPosition!,
          width: 60,
          height: 60,
          child: const Icon(
            Icons.my_location,
            color: Colors.redAccent,
            size: 35,
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  void _showCarwashInfo(String name, int carwashId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("View Services"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarwashServicesPage(
                      carwashName: name,
                      carwashId: carwashId,
                      cart: widget.cart,
                      bookings: widget.bookings,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition ??
        (widget.carwashes.isNotEmpty
            ? LatLng(
                double.tryParse(widget.carwashes[0]['latitude']?.toString() ?? '0') ?? 0.0,
                double.tryParse(widget.carwashes[0]['longitude']?.toString() ?? '0') ?? 0.0,
              )
            : const LatLng(-1.286389, 36.817223)); // Default Nairobi

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Carwashes (Map)"),
        backgroundColor: Colors.blueAccent,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 13,
          onTap: (_, __) => FocusScope.of(context).unfocus(),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.carwash.carwash_frontend',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
