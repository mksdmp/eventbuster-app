import 'package:flutter/material.dart';

import '../../app/constants.dart';
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
  String? _emailError;
  String? _passwordError;
  String? _captchaError;

  bool _validateFields() {
    final String email = controller.emailController.text.trim();
    final String password = controller.passwordController.text;
    final String captchaAnswer = controller.humanCheckController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Email is required' : null;
      _passwordError = password.isEmpty ? 'Password is required' : null;

      if (captchaAnswer.isEmpty) {
        _captchaError = 'Captcha answer is required';
      } else if (!controller.isCaptchaAnswerValid(captchaAnswer)) {
        _captchaError = 'Wrong human check answer';
      } else {
        _captchaError = null;
      }
    });

    return _emailError == null && _passwordError == null && _captchaError == null;
  }

  Future<void> handleLogin() async {
    if (!_validateFields()) {
      return;
    }

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
      Navigator.pushReplacementNamed(context, Routes.dashboard);
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
    final double logoWidth = (MediaQuery.sizeOf(context).width * 0.62)
        .clamp(255.0, 320.0)
        .toDouble();
    final double logoHeight = (logoWidth * 0.68).clamp(170.0, 205.0).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: logoHeight,
                    width: logoWidth,
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
                  const SizedBox(height: 8),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use your account credentials to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: controller.emailController,
                          hint: 'Enter your email',
                          errorText: _emailError,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() {
                                _emailError = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        CustomTextField(
                          controller: controller.passwordController,
                          hint: 'Enter your password',
                          isPassword: true,
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() {
                                _passwordError = null;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppConstants.appOrange,
                              fontSize: 13,
                            ),
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  controller.refreshCaptcha();
                                  _captchaError = null;
                                });
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
                          errorText: _captchaError,
                          onChanged: (_) {
                            if (_captchaError != null) {
                              setState(() {
                                _captchaError = null;
                              });
                            }
                          },
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
