import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class MyBookingsPage extends StatefulWidget {
  final String userId;
  const MyBookingsPage({super.key, required this.userId});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = ApiService.fetchMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.local_car_wash, color: Colors.redAccent),
                  title: Text(
                    booking.carwashName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service: ${booking.serviceName}'),
                      Text('Date: ${booking.timeSlot.toLocal()}'),
                      Text('Amount: \$${booking.amount}'),
                      Text('Status: ${booking.status.toUpperCase()}',
                          style: TextStyle(
                              color: booking.status == 'confirmed'
                                  ? Colors.green
                                  : Colors.orange)),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
