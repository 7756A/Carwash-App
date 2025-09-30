import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';

class TenantLoginPage extends StatefulWidget {
  const TenantLoginPage({super.key});

  @override
  State<TenantLoginPage> createState() => _TenantLoginPageState();
}

class _TenantLoginPageState extends State<TenantLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _loginTenant() async {
    setState(() => _loading = true);

    // TODO: connect with Django API using auth_service.dart
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _loading = false);

    // Navigate to dashboard
    Navigator.pushReplacementNamed(context, '/tenant-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Tenant Login",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: "Email",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: "Password",
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                // Login Button
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _loginTenant,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Login",
                            style: TextStyle(fontSize: 16)),
                      ),

                // Forgot Password
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text("Forgot Password?"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
