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
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Human check: What is 8 + 3?'),
                ),
                const SizedBox(height: 5),
                CustomTextField(
                  controller: controller.humanCheckController,
                  hint: 'Enter answer',
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: controller.isLoading ? 'Signing In...' : 'Sign In',
                  onTap: controller.isLoading ? () {} : handleLogin,
                ),
                const SizedBox(height: 15),
                const Text('Or continue with'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Google'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Facebook'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
