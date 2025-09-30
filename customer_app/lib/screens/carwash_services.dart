import 'package:flutter/material.dart';
import 'cart_page.dart';
import '../models/booking.dart';

class CarwashServicesPage extends StatefulWidget {
  final String carwashName;
  final List<Map<String, String>> cart;   // shared cart
  final List<Booking> bookings;           // shared bookings

  const CarwashServicesPage({
    super.key,
    required this.carwashName,
    required this.cart,
    required this.bookings,
  });

  @override
  State<CarwashServicesPage> createState() => _CarwashServicesPageState();
}

class _CarwashServicesPageState extends State<CarwashServicesPage> {
  final List<Map<String, String>> services = const [
    {'name': 'Basic Wash', 'price': '500'},
    {'name': 'Full Wash', 'price': '800'},
    {'name': 'Waxing', 'price': '1200'},
    {'name': 'Interior Cleaning', 'price': '700'},
  ];

  void addToCart(Map<String, String> service) {
    setState(() {
      widget.cart.add(service);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service['name'] ?? 'Service'} added to cart!')),
    );
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(
          cart: widget.cart,
          bookings: widget.bookings,
        ),
      ),
    ).then((_) => setState(() {})); // refresh badge if needed
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
              if (widget.cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${widget.cart.length}',
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
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(service['name'] ?? 'Unknown'),
              subtitle: Text('KSh ${service['price'] ?? '0'}'),
              trailing: ElevatedButton(
                child: const Text('Add'),
                onPressed: () => addToCart(service),
              ),
            ),
          );
        },
      ),
    );
  }
}
