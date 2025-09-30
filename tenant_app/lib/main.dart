import 'package:flutter/material.dart';
import 'screens/tenant_login.dart';
import 'screens/tenant_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tenant App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Start at the Tenant Login screen
      initialRoute: '/login',
      routes: {
        '/login': (context) => const TenantLoginPage(),
        '/tenant-dashboard': (context) => const TenantDashboardPage(),
        // later: '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
