import 'dart:math';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthController {
  AuthController() {
    refreshCaptcha();
  }

  final AuthService _authService = AuthService();
  final Random _random = Random();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final humanCheckController = TextEditingController();

  bool isLoading = false;
  int _captchaFirst = 0;
  int _captchaSecond = 0;

  String get captchaQuestion => 'Captcha: What is $_captchaFirst + $_captchaSecond?';

  Future<String?> login() async {
    if (emailController.text.isEmpty) {
      return 'Email required';
    }
    if (passwordController.text.isEmpty) {
      return 'Password required';
    }
    final int? captchaAnswer = int.tryParse(humanCheckController.text.trim());
    if (captchaAnswer != _captchaFirst + _captchaSecond) {
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

  void refreshCaptcha() {
    _captchaFirst = _random.nextInt(9) + 1;
    _captchaSecond = _random.nextInt(9) + 1;
    humanCheckController.clear();
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    humanCheckController.dispose();
  }
}
