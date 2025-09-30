import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://172.16.12.3:8000/api"; // your Django API

  // Register Customer
  static Future<Map<String, dynamic>> registerCustomer(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/customer/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    return _processResponse(response);
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/customer/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    return _processResponse(response);
  }

  // Get Nearby Carwashes
  static Future<List<dynamic>> getNearbyCarwashes() async {
    final response = await http.get(
      Uri.parse("$baseUrl/customers/carwashes/"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load carwashes");
    }
  }

  // Book Service
  static Future<Map<String, dynamic>> bookService(
    int carwashId,
    int serviceId,
    String date,
    String time,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/bookings/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "carwash_id": carwashId,
        "service_id": serviceId,
        "date": date,
        "time": time,
      }),
    );

    return _processResponse(response);
  }

  // Helper function
  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.statusCode}, ${response.body}");
    }
  }
}
