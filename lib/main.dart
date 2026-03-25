import 'package:flutter/material.dart';

import 'app/constants.dart';
import 'app/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color buttonOrange = Colors.orange;

    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.splash,
      routes: Routes.routes,
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.orange,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          actionTextColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonOrange,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: buttonOrange,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: buttonOrange,
            foregroundColor: Colors.white,
            side: const BorderSide(color: buttonOrange),
          ),
        ),
      ),
    );
  }
}
