import 'package:flutter/material.dart';
import '../models/booking.dart';
import 'booking.dart'; // BookingPage

class BookingsScreen extends StatefulWidget {
  final List<Booking> bookings;
  final List<Map<String, String>> cart; // shared cart

  const BookingsScreen({super.key, required this.bookings, required this.cart});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  void _goToBooking() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty! Add services first.")),
      );
      return;
    }

    final serviceNames =
        widget.cart.map((item) => item['name'] ?? 'Service').toList();

    final newBooking = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingPage(cart: serviceNames)),
    );

    if (newBooking != null && newBooking is Booking) {
      setState(() {
        widget.bookings.add(newBooking); // add booking
        widget.cart.clear(); // clear cart
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Booking created successfully! Cart cleared.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: widget.bookings.isEmpty
          ? const Center(child: Text("No bookings yet"))
          : ListView.builder(
              itemCount: widget.bookings.length,
              itemBuilder: (context, index) {
                final b = widget.bookings[index];
                return Card(
                  child: ListTile(
                    title: Text("${b.dateTime.toLocal()}".split(' ')[0]),
                    subtitle: Text("${b.serviceName}\nPayment: ${b.paymentDetails}"),
                    trailing: Text(
                      b.status,
                      style: TextStyle(
                        color: b.status == "Confirmed"
                            ? Colors.green
                            : b.status == "Pending"
                                ? Colors.orange
                                : b.status == "Cancelled"
                                    ? Colors.red
                                    : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToBooking,
        child: const Icon(Icons.add),
      ),
    );
  }
}
