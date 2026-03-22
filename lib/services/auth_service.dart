import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _loginUrl = 'http://localhost:5000/api/auth/login';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  Future<bool> login(String email, String password) async {
    final http.Response response = await http.post(
      Uri.parse(_loginUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return false;
    }

    final bool success = decoded['success'] == true;
    final Map<String, dynamic> data = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final String token = (data['token'] ?? '').toString();

    if (!success || token.isEmpty) {
      return false;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);

    final dynamic user = data['user'];
    if (user is Map<String, dynamic>) {
      await prefs.setString(userKey, jsonEncode(user));
    }

    return true;
  }

  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }
}
