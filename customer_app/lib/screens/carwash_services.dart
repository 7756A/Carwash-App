import 'package:flutter/material.dart';
import 'cart_page.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/cart_storage.dart';

class CarwashServicesPage extends StatefulWidget {
  final String carwashName;
  final int carwashId;
  final List<Map<String, dynamic>> cart;
  final List<Booking> bookings;

  const CarwashServicesPage({
    super.key,
    required this.carwashName,
    required this.carwashId,
    required this.cart,
    required this.bookings,
  });

  @override
  State<CarwashServicesPage> createState() => _CarwashServicesPageState();
}

class _CarwashServicesPageState extends State<CarwashServicesPage> {
  late Future<List<Map<String, dynamic>>> _services;
  late List<Map<String, dynamic>> _cart;

  @override
  void initState() {
    super.initState();
    _cart = List<Map<String, dynamic>>.from(widget.cart);
    _services = ApiService.getCarwashServices(widget.carwashId.toString());
  }

  /// ✅ Safe add-to-cart method
  Future<void> _addToCart(Map<String, dynamic> service) async {
    final int carwashId = widget.carwashId;

    // Ensure carwash ID is valid
    if (carwashId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid carwash ID")),
      );
      return;
    }

    // Extract and clean service data
    final int serviceId = service['id'] is int
        ? service['id']
        : int.tryParse(service['id']?.toString() ?? '') ?? 0;

    final double servicePrice = service['price'] is num
        ? (service['price'] as num).toDouble()
        : double.tryParse(service['price']?.toString() ?? '0') ?? 0.0;

    if (serviceId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid service ID")),
      );
      return;
    }

    final item = {
      "id": serviceId,
      "carwash_id": carwashId,
      "name": service['name']?.toString() ?? "Unknown",
      "price": servicePrice,
    };

    setState(() {
      _cart.add(item);
    });

    final customerId = await AuthService().getCustomerId();
    if (customerId != null) {
      await CartStorage.saveCart(customerId, _cart);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['name']} added to cart!')),
      );
    }
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cart: _cart,
          bookings: widget.bookings,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.carwashName),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: goToCart,
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
        future: _services,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No services found"));
          }

          final services = snapshot.data!;
          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(service['name'] ?? 'Unknown'),
                  subtitle: Text("KSh ${service['price'] ?? '0'}"),
                  trailing: ElevatedButton(
                    onPressed: () => _addToCart(service), // ✅ now safe
                    child: const Text('Add'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
