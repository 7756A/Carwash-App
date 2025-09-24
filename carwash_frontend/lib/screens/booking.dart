
import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  final List<Map<String, String>> cart;
  const BookingPage({super.key, required this.cart});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String? selectedTime;
  String paymentMethod = "M-Pesa";
  final TextEditingController mpesaController = TextEditingController();

  double getTotal() {
    double total = 0;
    for (var item in widget.cart) {
      total += double.tryParse(item['price'] ?? '0') ?? 0;
    }
    return total;
  }

  void confirmBooking() {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a time slot")),
      );
      return;
    }
    if (paymentMethod == "M-Pesa" && mpesaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your M-Pesa number")),
      );
      return;
    }

    // TODO: Connect to Django backend API for booking + payment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Booking confirmed at $selectedTime via $paymentMethod"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your Services",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...widget.cart.map((item) => ListTile(
                  title: Text(item['name']!),
                  trailing: Text("KSh ${item['price']}"),
                )),
            const Divider(),

            // Time slot selection
            const Text("Select Time Slot",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              hint: const Text("Choose a time"),
              value: selectedTime,
              items: [
                "Today 2:00 PM",
                "Today 4:00 PM",
                "Tomorrow 10:00 AM",
                "Tomorrow 12:00 PM",
              ].map((slot) {
                return DropdownMenuItem(value: slot, child: Text(slot));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedTime = value);
              },
            ),

            const SizedBox(height: 20),

            // Payment method selection
            const Text("Select Payment Method",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: paymentMethod,
              items: ["M-Pesa", "Visa", "PayPal"].map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) {
                setState(() => paymentMethod = value!);
              },
            ),

            if (paymentMethod == "M-Pesa") ...[
              TextField(
                controller: mpesaController,
                decoration: const InputDecoration(
                  labelText: "M-Pesa Number",
                  hintText: "e.g. 0712345678",
                ),
                keyboardType: TextInputType.phone,
              ),
            ],

            const Spacer(),

            // Total + Confirm
            Text("Total: KSh ${getTotal()}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: confirmBooking,
              child: const Text("Confirm & Pay"),
            )
          ],
        ),
      ),
    );
  }
}
