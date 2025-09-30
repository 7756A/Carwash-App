import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingPage extends StatefulWidget {
  final List<String> cart;

  const BookingPage({super.key, required this.cart});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String? paymentMethod;
  final TextEditingController mpesaController = TextEditingController();
  final TextEditingController paypalController = TextEditingController();
  final TextEditingController bankController = TextEditingController();

  Future<void> _pickDate(BuildContext context) async {
    final today = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(today.year + 1),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (pickedTime != null) {
      if (pickedTime.hour >= 7 && pickedTime.hour <= 18) {
        setState(() => selectedTime = pickedTime);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select time between 7 AM and 6 PM")),
        );
      }
    }
  }

  void _confirmBooking() {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select both date and time")));
      return;
    }

    if (paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a payment method")));
      return;
    }

    String paymentDetails = "";
    if (paymentMethod == "M-Pesa") {
      if (mpesaController.text.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Enter your M-Pesa number")));
        return;
      }
      paymentDetails = "M-Pesa: ${mpesaController.text}";
    } else if (paymentMethod == "PayPal") {
      if (paypalController.text.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Enter your PayPal email")));
        return;
      }
      paymentDetails = "PayPal: ${paypalController.text}";
    } else if (paymentMethod == "Bank") {
      if (bankController.text.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Enter your Bank account number")));
        return;
      }
      paymentDetails = "Bank: ${bankController.text}";
    }

    final bookingDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final booking = Booking(
      serviceName: widget.cart.join(", "),
      dateTime: bookingDateTime,
      paymentMethod: paymentMethod!,
      paymentDetails: paymentDetails,
      status: "Pending", // <-- default status
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking created successfully!")),
    );

    Navigator.pop(context, booking); // Return booking to BookingsScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Car Wash")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Items in cart: ${widget.cart.join(", ")}"),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _pickDate(context),
              child: const Text("Select Date"),
            ),
            if (selectedDate != null)
              Text("Selected Date: ${selectedDate!.toLocal()}".split(' ')[0]),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _pickTime(context),
              child: const Text("Select Time"),
            ),
            if (selectedTime != null)
              Text("Selected Time: ${selectedTime!.format(context)}"),
            const SizedBox(height: 30),

            const Text("Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            RadioListTile(
              title: const Text("M-Pesa"),
              value: "M-Pesa",
              groupValue: paymentMethod,
              onChanged: (value) => setState(() => paymentMethod = value),
            ),
            if (paymentMethod == "M-Pesa")
              TextField(
                controller: mpesaController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "M-Pesa Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),

            RadioListTile(
              title: const Text("PayPal"),
              value: "PayPal",
              groupValue: paymentMethod,
              onChanged: (value) => setState(() => paymentMethod = value),
            ),
            if (paymentMethod == "PayPal")
              TextField(
                controller: paypalController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "PayPal Email",
                  border: OutlineInputBorder(),
                ),
              ),

            RadioListTile(
              title: const Text("Bank"),
              value: "Bank",
              groupValue: paymentMethod,
              onChanged: (value) => setState(() => paymentMethod = value),
            ),
            if (paymentMethod == "Bank")
              TextField(
                controller: bankController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Bank Account Number",
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _confirmBooking,
              child: const Text("Confirm Booking"),
            ),
          ],
        ),
      ),
    );
  }
}
