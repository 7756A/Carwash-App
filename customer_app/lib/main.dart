import 'package:flutter/material.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/main_navigation.dart';
import '../models/booking.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carwash App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/signup',
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        // ✅ Pass empty cart/bookings initially; these will be replaced after login
        '/main': (context) => MainNavigation(
              initialCart: [],
              initialBookings: [],
            ),
      },
    );
  }
}
