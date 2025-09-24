import 'package:flutter/material.dart';
import 'package:carwash_frontend/screens/signup_page.dart';
import 'package:carwash_frontend/screens/nearby_carwash.dart';
import 'package:carwash_frontend/screens/cart_page.dart'; // import CartPage
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SignupPage(), // Start with MainScreen
    );
  }
}

// ===== MAIN SCREEN WITH NAV BAR =====
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Global cart accessible from MainScreen
  final List<Map<String, String>> cart = [];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      NearbyCarwashPage(cart: cart), // pass cart to NearbyCarwashPage
      const BookingsScreen(),
      const ProfileScreen(),
    ];
  }

  void goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage(cart: cart)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carwash App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: goToCart,
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_car_wash),
            label: "Carwashes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// ===== PLACEHOLDER SCREENS =====
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Bookings Screen"),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Profile Screen"),
      ),
    );
  }
}
