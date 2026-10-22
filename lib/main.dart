import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() => runApp(const SmartbookApp());

class SmartbookApp extends StatelessWidget {
  const SmartbookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SmartBook · CDI',
    debugShowCheckedModeBanner: false,
    initialRoute: AppRoutes.login,
    onGenerateRoute: (settings) {
      switch (settings.name) {
        case AppRoutes.login:
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        case AppRoutes.home:
          return MaterialPageRoute(builder: (context) => const HomeScreen());
        default:
          return MaterialPageRoute(builder: (context) => const LoginScreen());
      }
    },
  );
}
