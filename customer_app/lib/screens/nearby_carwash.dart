import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/cart_storage.dart';
import 'carwash_services.dart';
import 'carwash_map_page.dart';
import 'cart_page.dart';

class NearbyCarwashPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final List<Booking> bookings;

  const NearbyCarwashPage({
    super.key,
    required this.cart,
    required this.bookings,
  });

  @override
  State<NearbyCarwashPage> createState() => _NearbyCarwashPageState();
}

class _NearbyCarwashPageState extends State<NearbyCarwashPage> {
  late List<Map<String, dynamic>> _cart;
  late List<Booking> _bookings;
  late Future<List<Map<String, dynamic>>> _carwashFuture;
  List<Map<String, dynamic>> _carwashes = [];

  @override
  void initState() {
    super.initState();
    _cart = widget.cart;
    _bookings = widget.bookings;
    _carwashFuture = ApiService.getNearbyCarwashes();
    _loadSavedCart();
  }

  Future<void> _loadSavedCart() async {
    final customerId = await AuthService().getCustomerId();
    if (customerId != null) {
      final savedCart = await CartStorage.loadCart(customerId);
      setState(() {
        _cart = savedCart;
      });
    }
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cart: _cart,
          bookings: _bookings,
        ),
      ),
    ).then((_) => _loadSavedCart());
  }

  void _goToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarwashMapPage(
          carwashes: _carwashes,
          cart: _cart,
          bookings: _bookings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Carwashes"),
        actions: [
          // ✅ Cart icon with item count
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _goToCart,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _carwashFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No carwashes found"));
          }

          final carwashes = snapshot.data!;
          _carwashes = carwashes;

          return ListView.builder(
            itemCount: carwashes.length,
            itemBuilder: (context, index) {
              final carwash = carwashes[index];
              final distance = (carwash['distance_km'] is num)
                  ? (carwash['distance_km'] as num).toStringAsFixed(2)
                  : carwash['distance_km']?.toString() ?? "--";

              final carwashId = carwash['id'] is int
                  ? carwash['id']
                  : int.tryParse(carwash['id'].toString()) ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(carwash['name'] ?? "Unknown"),
                  subtitle: Text(
                    "Location: ${carwash['location'] ?? "No location"}\n"
                    "Distance: $distance km",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarwashServicesPage(
                          carwashName: carwash['name'] ?? "Carwash",
                          carwashId: carwashId,
                          cart: _cart,
                          bookings: _bookings,
                          // ✅ No addToCart here anymore
                        ),
                      ),
                    );
                    _loadSavedCart(); // refresh cart count after returning
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'View Nearby on Map',
        onPressed: _goToMap,
        child: const Icon(Icons.map),
      ),
    );
  }
}
