import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController controller = AuthController();

  Future<void> handleLogin() async {
    setState(() {
      controller.isLoading = true;
    });

    final String? result = await controller.login();

    if (!mounted) {
      return;
    }

    setState(() {
      controller.isLoading = false;
    });

    if (result == null) {
      Navigator.pushReplacementNamed(context, Routes.attendees);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 110,
                    width: 180,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use your account credentials to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: controller.emailController,
                          hint: 'Enter your email',
                        ),
                        const SizedBox(height: 15),
                        CustomTextField(
                          controller: controller.passwordController,
                          hint: 'Enter your password',
                          isPassword: true,
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                controller.captchaQuestion,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(controller.refreshCaptcha);
                              },
                              icon: const Icon(Icons.refresh, size: 20),
                              tooltip: 'Refresh captcha',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: controller.humanCheckController,
                          hint: 'Enter answer',
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: controller.isLoading ? 'Signing In...' : 'Sign In',
                          onTap: controller.isLoading ? () {} : handleLogin,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
