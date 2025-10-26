import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartStorage {
  static String _cartKey(String userId) => 'cart_$userId';

  /// ✅ Save cart for a specific user (supports dynamic types)
  static Future<void> saveCart(String userId, List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey(userId), jsonEncode(cart));
  }

  /// ✅ Load cart for a specific user
  static Future<List<Map<String, dynamic>>> loadCart(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey(userId));

    if (cartString == null || cartString.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(cartString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error decoding cart JSON: $e');
      return [];
    }
  }

  /// ✅ Clear cart
  static Future<void> clearCart(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey(userId));
  }
}
