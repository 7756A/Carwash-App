import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/cart_storage.dart';

class BookingPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double totalAmount;

  const BookingPage({
    super.key,
    required this.cart,
    required this.totalAmount,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String? paymentMethod;
  final TextEditingController mpesaController = TextEditingController();
  final TextEditingController paypalController = TextEditingController();

  /// ✅ Map frontend names to backend choices
  String _mapPaymentMethod(String method) {
    switch (method) {
      case "M-Pesa":
        return "mpesa";
      case "PayPal":
        return "paypal";
      case "Visa":
        return "visa";
      default:
        return "mpesa"; // fallback
    }
  }

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
            content: Text("Please select time between 7 AM and 6 PM"),
          ),
        );
      }
    }
  }

  Future<void> _confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both date and time")),
      );
      return;
    }

    if (paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method")),
      );
      return;
    }

    String? paymentDetails;
    String? mpesaNumber;

    if (paymentMethod == "M-Pesa") {
      if (mpesaController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter your M-Pesa number")),
        );
        return;
      }
      mpesaNumber = mpesaController.text;
      paymentDetails = "M-Pesa: $mpesaNumber";
    } else if (paymentMethod == "PayPal") {
      if (paypalController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter your PayPal email")),
        );
        return;
      }
      paymentDetails = "PayPal: ${paypalController.text}";
    }

    // ✅ Combine date + time properly
    final bookingDate = selectedDate!;
    final formattedDateTime = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    final timeSlot = "${formattedDateTime.year.toString().padLeft(4, '0')}-"
        "${formattedDateTime.month.toString().padLeft(2, '0')}-"
        "${formattedDateTime.day.toString().padLeft(2, '0')} "
        "${formattedDateTime.hour.toString().padLeft(2, '0')}:"
        "${formattedDateTime.minute.toString().padLeft(2, '0')}";

    // ✅ Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Text(
          "Date: ${bookingDate.toString().split(' ')[0]}\n"
          "Time: ${selectedTime!.format(context)}\n"
          "Payment: $paymentMethod\n"
          "Total: KSh ${widget.totalAmount.toStringAsFixed(2)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authService = AuthService();
      final token = await authService.getToken();
      final customerId = await authService.getCustomerId();

      if (customerId == null || customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No customer logged in")),
        );
        return;
      }

      final cart = await CartStorage.loadCart(customerId);
      if (cart.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Your cart is empty")),
        );
        return;
      }

      // ✅ Extract service IDs
      final serviceIds = cart.map((item) {
        final idRaw = item['id'];
        if (idRaw is int) return idRaw;
        if (idRaw is String) return int.tryParse(idRaw);
        return null;
      }).whereType<int>().toList();

      if (serviceIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cart contains invalid service IDs")),
        );
        return;
      }

      // ✅ Extract carwash ID
      final carwashIdRaw = cart.first['carwash_id'];
      final carwashId = carwashIdRaw is int
          ? carwashIdRaw
          : int.tryParse(carwashIdRaw.toString());

      if (carwashId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid carwash ID in cart")),
        );
        return;
      }

      // ✅ Send booking request
      final response = await ApiService.createBooking(
        token: token!,
        serviceIds: serviceIds,
        carwashId: carwashId,
        date: bookingDate.toIso8601String().split('T')[0],
        timeSlot: timeSlot,
        paymentMethod: _mapPaymentMethod(paymentMethod!),
        mpesaNumber: mpesaNumber,
      );

      if (response['status'] == 'payment_initiated' ||
          response['message'] == 'Bookings created successfully') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking(s) created successfully!")),
        );

        await CartStorage.clearCart(customerId);

        Navigator.pop(context, response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Booking failed: ${response['error'] ?? response['message'] ?? 'Unknown error'}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Car Wash")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Items in cart: ${widget.cart.map((e) => e['name']).join(", ")}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              "Total Amount: KSh ${widget.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
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
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

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
              title: const Text("Visa"),
              value: "Visa",
              groupValue: paymentMethod,
              onChanged: (value) => setState(() => paymentMethod = value),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Confirm Booking"),
            ),
          ],
        ),
      ),
    );
  }
}
