import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _authService = AuthService();

  Future<http.Response> get(String url) async {
    final token = await _authService.getToken();
    return http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token', // or 'Bearer $token' for JWT
        'Content-Type': 'application/json',
      },
    );
  }

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    return http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}
