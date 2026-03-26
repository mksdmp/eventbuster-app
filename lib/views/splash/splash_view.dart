import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final String? token = await _authService.getToken();

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      token != null && token.trim().isNotEmpty ? Routes.dashboard : Routes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = (MediaQuery.sizeOf(context).width * 0.58)
        .clamp(270.0, 340.0)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.jpeg',
          width: logoSize,
          height: logoSize,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image_not_supported_rounded,
              size: 100,
              color: AppConstants.appOrange,
            );
          },
        ),
      ),
    );
  }
}
