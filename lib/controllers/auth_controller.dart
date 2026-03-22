import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final humanCheckController = TextEditingController();

  bool isLoading = false;

  Future<String?> login() async {
    if (emailController.text.isEmpty) {
      return 'Email required';
    }
    if (passwordController.text.isEmpty) {
      return 'Password required';
    }
    if (humanCheckController.text != '11') {
      return 'Wrong human check answer';
    }

    isLoading = true;

    final bool success = await _authService.login(
      emailController.text,
      passwordController.text,
    );

    isLoading = false;

    if (success) {
      return null;
    }
    return 'Invalid credentials';
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    humanCheckController.dispose();
  }
}
