import 'package:flutter/material.dart';
import 'package:carwash_frontend/screens/cart_page.dart';
import 'package:carwash_frontend/screens/nearby_carwash.dart';
import 'package:carwash_frontend/screens/signup_page.dart';
import 'package:carwash_frontend/screens/booking_screen.dart'; // Import external bookings screen
import 'package:carwash_frontend/models/booking.dart';
import 'package:carwash_frontend/screens/profile.dart';

void main() {
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carwash Customer App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignupPage(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Map<String, String>> cart = []; // shared cart
  final List<Booking> bookings = []; // shared bookings

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      NearbyCarwashPage(cart: cart, bookings: bookings),
      BookingsScreen(bookings: bookings, cart: cart), // pass shared cart & bookings
      const ProfilePage(),
    ];
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage(cart: cart, bookings: bookings)),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carwash App"),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart), onPressed: goToCart),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_car_wash), label: "Carwashes"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

