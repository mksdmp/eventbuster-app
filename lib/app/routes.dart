import 'package:flutter/material.dart';

import '../views/dashboard/dashboard_view.dart';
import '../views/auth/login_view.dart';
import '../views/splash/splash_view.dart';

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const attendees = '/attendees';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashView(),
    login: (context) => const LoginView(),
    dashboard: (context) => const DashboardView(),
    attendees: (context) => const DashboardView(),
  };
}
