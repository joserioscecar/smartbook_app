import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'screens/inicio_screen.dart';
import 'screens/login_screen.dart';
import 'screens/restablecer_contrasena_screen.dart';

void main() => runApp(const SmartbookApp());

class SmartbookApp extends StatelessWidget {
  const SmartbookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SmartBook · CDI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE12D2E),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
    ),
    initialRoute: AppRoutes.login,
    onGenerateRoute: (settings) {
      switch (settings.name) {
        case AppRoutes.login:
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        case AppRoutes.home:
          return MaterialPageRoute(builder: (context) => const InicioScreen());
        case AppRoutes.resetPassword:
          return MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          );
        default:
          return MaterialPageRoute(builder: (context) => const LoginScreen());
      }
    },
  );
}
