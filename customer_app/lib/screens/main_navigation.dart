import 'package:flutter/material.dart';
import 'nearby_carwash.dart';
import 'booking_screen.dart';
import 'profile.dart'; // Replace with your actual ProfilePage
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'cart_page.dart';
import 'carwash_map_page.dart';
import '../services/api_service.dart';


class MainNavigation extends StatefulWidget {
  final List<Map<String, dynamic>> initialCart;
  final List<Booking> initialBookings;

  const MainNavigation({
    super.key,
    required this.initialCart,
    required this.initialBookings,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late List<Map<String, dynamic>> cart;
  late List<Booking> bookings;
  String? userId;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    cart = widget.initialCart;
    bookings = widget.initialBookings;

    // Initialize pages with placeholders; userId will be loaded asynchronously
    _pages = [
      NearbyCarwashPage(cart: cart, bookings: bookings),
      MyBookingsPage(userId: ""), // placeholder until userId is loaded
      const ProfilePage(),
    ];

    _loadUserId();
  }

  Future<void> _loadUserId() async {
    userId = await AuthService().getCustomerId();
    setState(() {
      _pages = [
        NearbyCarwashPage(cart: cart, bookings: bookings),
        MyBookingsPage(userId: userId ?? ""),
        const ProfilePage(),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(cart: cart, bookings: bookings),
      ),
    ).then((_) => setState(() {})); // refresh state when returning
  }

void _goToMap() async {
  try {
    // Fetch nearby carwashes using user's current location
    final nearbyCarwashes = await ApiService.getNearbyCarwashes();

    // Navigate to map page with carwash data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarwashMapPage(
          carwashes: nearbyCarwashes,
          cart: cart,
          bookings: bookings,
        ),
      ),
    );
  } catch (e) {
    // Handle any errors gracefully
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load nearby carwashes: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Wash App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: "View on Map",
            onPressed: _goToMap,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _goToCart,
              ),
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
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_car_wash),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
