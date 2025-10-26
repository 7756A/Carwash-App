import 'package:flutter/material.dart';
import 'package:carwash_frontend/screens/login_page.dart';
import 'package:carwash_frontend/screens/signup_page.dart';
import 'package:carwash_frontend/screens/nearby_carwash.dart';
import 'models/booking.dart';

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
      // 🟢 Start with SignUpPage
      home: const SignupPage(),
      // Optional: Named routes if you want to navigate easily
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/nearby': (context) => NearbyCarwashPage(
              cart: const [],
              bookings: const <Booking>[],
            ),
      },
    );
  }
}
