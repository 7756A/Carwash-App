import 'package:flutter/material.dart';
import 'package:carwash_frontend/screens/booking.dart';
import '../models/booking.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, String>> cart;
  final List<Booking> bookings;

  const CartPage({super.key, required this.cart, required this.bookings});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    int total = widget.cart.fold(
      0,
      (sum, item) => sum + int.tryParse(item['price'] ?? '0')!,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: widget.cart.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final service = widget.cart[index];
                      return ListTile(
                        title: Text(service['name'] ?? 'Unknown'),
                        subtitle: Text('KSh ${service['price'] ?? '0'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              widget.cart.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Total: KSh $total",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: widget.cart.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  final serviceNames =
                      widget.cart.map((item) => item['name'] ?? 'Service').toList();

                  final newBooking = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPage(cart: serviceNames),
                    ),
                  );

                  if (newBooking != null && newBooking is Booking) {
                    setState(() {
                      widget.cart.clear(); // clear cart
                      widget.bookings.add(newBooking); // add to bookings
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Booking created successfully! Cart cleared."),
                      ),
                    );

                    Navigator.pop(context); // go back to main screen
                  }
                },
                child: const Text('Proceed to Checkout'),
              ),
            ),
    );
  }
}
