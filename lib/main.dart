import 'package:flutter/material.dart';

import 'app/constants.dart';
import 'app/routes.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final String? token = await AuthService().getToken();
  final bool isSignedIn = token != null && token.trim().isNotEmpty;

  runApp(MyApp(initialRoute: isSignedIn ? Routes.dashboard : Routes.login));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.initialRoute,
  });

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: Routes.routes,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.appOrange,
          primary: AppConstants.appOrange,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppConstants.appOrange,
          contentTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          actionTextColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.appOrange,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: AppConstants.appOrange,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: AppConstants.appOrange,
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppConstants.appOrange),
          ),
        ),
      ),
    );
  }
}
