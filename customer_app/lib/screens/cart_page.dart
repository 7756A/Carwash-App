import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'booking.dart';
import '../utils/cart_storage.dart';
import '../services/auth_service.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final List<Booking> bookings;

  const CartPage({
    super.key,
    this.cart = const [],
    this.bookings = const [],
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _cartItems = List.from(widget.cart);
    _loadSavedCart();
  }

  Future<void> _loadSavedCart() async {
    final customerId = await AuthService().getCustomerId();
    if (customerId == null) return;

    final savedCart = await CartStorage.loadCart(customerId);
    if (mounted) {
      setState(() {
        _cartItems = savedCart.map((item) {
          // Convert IDs to integers if they aren't already
          return {
            "id": item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()),
            "carwash_id": item["carwash_id"] is int
                ? item["carwash_id"]
                : int.tryParse(item["carwash_id"].toString()),
            "name": item["name"] ?? 'Service',
            "price": item["price"] ?? 0.0,
          };
        }).toList();
      });
    }
  }

  Future<void> _saveCart() async {
    final customerId = await AuthService().getCustomerId();
    if (customerId != null) {
      await CartStorage.saveCart(customerId, _cartItems);
    }
  }

  void _removeItem(int index) async {
    setState(() => _cartItems.removeAt(index));
    await _saveCart();
  }

  Future<void> _clearCart() async {
    final customerId = await AuthService().getCustomerId();
    setState(() => _cartItems.clear());
    if (customerId != null) {
      await CartStorage.clearCart(customerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _cartItems.fold<double>(0.0, (sum, item) {
      final price = item['price'] is double
          ? item['price']
          : double.tryParse(item['price'].toString()) ?? 0.0;
      return sum + price;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: _cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final service = _cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(service['name'] ?? 'Unknown Service'),
                          subtitle: Text('KSh ${service['price'] ?? '0'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Total: KSh ${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    // ✅ Proceed to BookingPage
                    final response = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingPage(
                          cart: _cartItems,
                          totalAmount: total,
                        ),
                      ),
                    );

                    // ✅ Clear cart on successful booking
                    if (response != null) {
                      await _clearCart();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Booking created successfully! Cart cleared.",
                            ),
                          ),
                        );
                        Navigator.pop(context, response);
                      }
                    }
                  },
                  child: const Text('Proceed to Checkout'),
                ),
              ),
            ),
    );
  }
}
