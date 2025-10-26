import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "http://10.136.142.129:8000/api";

  /// ---------------- REGISTER ----------------
  static Future<Map<String, dynamic>> registerCustomer(
      String username, String email, String password) async {
    try {
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
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  /// ---------------- LOGIN ----------------
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/customer/login/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final result = _processResponse(response);

      if (result.containsKey("access") && result.containsKey("customer_id")) {
        await AuthService().saveToken(
          result["access"],
          customerId: result["customer_id"].toString(),
        );
      }

      return result;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// ---------------- NEARBY CARWASHES ----------------
  static Future<List<Map<String, dynamic>>> getNearbyCarwashes() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return getNearbyCarwashesForCoords(pos.latitude, pos.longitude);
  }

  static Future<List<Map<String, dynamic>>> getNearbyCarwashesForCoords(
      double lat, double lon) async {
    final url = Uri.parse("$baseUrl/customer/nearby/?lat=$lat&lon=$lon");
    final token = await AuthService().getToken();

    if (token == null) throw Exception("User is not logged in.");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return List<Map<String, dynamic>>.from(data);
      throw Exception("Invalid response format");
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized: invalid or expired token.");
    } else {
      throw Exception(
          "Failed to load nearby carwashes: ${response.statusCode}, ${response.body}");
    }
  }

  /// ---------------- CARWASH SERVICES ----------------
  static Future<List<Map<String, dynamic>>> getCarwashServices(
      String carwashId) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception("User is not logged in.");

    final response = await http.get(
      Uri.parse("$baseUrl/customer/carwash/$carwashId/services/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to load services: ${response.statusCode}");
    }
  }

  /// ---------------- PAYMENT MAPPING ----------------
  static String mapPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'm-pesa':
        return 'mpesa';
      case 'paypal':
        return 'paypal';
      case 'visa':
        return 'visa';
      default:
        return method.toLowerCase();
    }
  }

  /// ---------------- CREATE BOOKING ----------------
  static Future<Map<String, dynamic>> createBooking({
    required String token,
    required List<int> serviceIds,
    required int carwashId,
    required String date,
    required String timeSlot,
    required String paymentMethod,
    String? mpesaNumber,
    String? paymentReference, // ✅ Add this parameter
  }) async {
    final url = Uri.parse("$baseUrl/bookings/customer/bookings/create/");

    final body = {
      "service_ids": serviceIds,
      "carwash": carwashId,
      "date": date,
      "time_slot": timeSlot,
      "payment_method": mapPaymentMethod(paymentMethod),
      if (mpesaNumber != null) "mpesa_number": mpesaNumber,
      if (paymentReference != null) "payment_reference": paymentReference,
    };

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create booking: ${response.body}");
    }
  }

  /// ---------------- HELPER ----------------
  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Error: ${response.statusCode}, ${response.body}");
    }
  }
}
