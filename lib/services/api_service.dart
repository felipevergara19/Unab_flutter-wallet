import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS/Web/Windows
  // Note: On physical Android devices, use your PC's local IP (e.g. 192.168.x.x)
  // Use 10.0.2.2 for Android emulator, localhost for iOS/Web/Windows
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }
    // Check for Android specifically
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (e) {
      // defaultTargetPlatform might throw on some setups if not imported,
      // but kIsWeb check protects against web runtime errors for dart:io usage usually.
      // However, defaultTargetPlatform is safe in flutter context.
    }
    // Default for iOS, Windows, macOS, Linux
    return 'http://127.0.0.1:5000/api';
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          jsonDecode(response.body)['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<List<dynamic>> getProducts(int userId) async {
    final url = Uri.parse('$baseUrl/products?user_id=$userId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> addProduct(
    String name,
    double price,
    String description,
    String type,
    int userId,
  ) async {
    final url = Uri.parse('$baseUrl/products');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'price': price,
          'description': description,
          'type': type,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add product');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
