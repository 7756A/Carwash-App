import 'package:flutter/material.dart';
import 'package:carwash_frontend/screens/booking.dart';

class CartPage extends StatelessWidget {
  final List<Map<String, String>> cart;
  const CartPage({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    int total = cart.fold(0, (sum, item) => sum + int.parse(item['price']!));

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final service = cart[index];
                      return ListTile(
                        title: Text(service['name']!),
                        subtitle: Text('KSh ${service['price']}'),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Total: KSh $total",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPage(cart: cart),
                    ),
                  );
                },
                child: const Text('Proceed to Checkout'),
              ),
            ),
    );
  }
}

