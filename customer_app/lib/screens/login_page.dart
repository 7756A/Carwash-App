import 'package:flutter/material.dart';
import 'package:carwash_frontend/screens/forget_password.dart';
import 'package:carwash_frontend/screens/main_navigation.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import '../utils/cart_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var result = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // ✅ Extract customer_id from API response
      final customerId = result['customer_id'].toString();

      // ✅ Save the JWT token along with customer_id
      await AuthService().saveToken(result['access'], customerId: customerId);

      // ✅ Load cart specific to this customer
      final savedCart = await CartStorage.loadCart(customerId);

      // ✅ Initialize empty bookings list
      final List<Booking> bookings = [];

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome! Login successful')),
      );

      // ✅ Navigate to NearbyCarwashPage with user-specific cart
     Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => MainNavigation(
      initialCart: savedCart.isNotEmpty ? savedCart : [],
      initialBookings: bookings,
    ),
  ),
);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username or Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgetPassword(),
                  ),
                );
              },
              child: const Text("Forgot Password?"),
            ),
          ],
        ),
      ),
    );
  }
}
