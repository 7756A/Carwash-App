import 'package:flutter/material.dart';
import 'cart_page.dart'; // Import the cart page

class CarwashServicesPage extends StatefulWidget {
  final String carwashName;
  final List<Map<String, String>> cart; // ← shared cart
  const CarwashServicesPage({super.key, required this.carwashName, required this.cart});

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
      widget.cart.add(service); // ← add to shared cart
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service['name']} added to cart!')),
    );
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(cart: widget.cart), // ← use shared cart
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.carwashName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: goToCart,
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
              title: Text(service['name']!),
              subtitle: Text('KSh ${service['price']}'),
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
