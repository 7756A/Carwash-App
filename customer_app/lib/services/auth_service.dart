import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  /// Save token and optional customer_id
  Future<void> saveToken(String token, {String? customerId}) async {
    await _storage.write(key: 'auth_token', value: token);
    if (customerId != null) {
      await _storage.write(key: 'customer_id', value: customerId);
    }
  }

  /// Get JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Get customer_id
  Future<String?> getCustomerId() async {
    return await _storage.read(key: 'customer_id');
  }

  /// Delete token + customer_id
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'customer_id');
  }
}
