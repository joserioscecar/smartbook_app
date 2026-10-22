import 'package:flutter/material.dart';
import 'package:smartbook_app/models/login/login_request.dart';
import 'package:smartbook_app/services/remote/login_service.dart';

import '../config/app_theme.dart';
import '../routes/app_routes.dart';
import '../widgets/buttons/primary_button.dart';
import '../widgets/fields/custom_text_field.dart';
import '../widgets/fields/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginService _loginService = LoginService();

  final _emailController = TextEditingController(
    text: "centrodeidiomas@cecar.edu.co",
  );
  final _passwordController = TextEditingController(text: "AdminCDI2026");

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    var request = LoginRequest(
      email: _emailController.text,
      password: _passwordController.text,
    );
    var response = await _loginService.login(request);
    if (response != null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: Image.asset(
                        'assets/images/cdi_logo.png',
                        width: 220,
                        semanticLabel: 'CDI Centro de Idiomas CECAR',
                      ),
                    ),

                    const SizedBox(height: 8),

                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      hintText: 'nombre@correo.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      autocorrect: false,
                    ),
                    const SizedBox(height: 18),
                    PasswordField(
                      controller: _passwordController,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Entrar', onPressed: _login),
                    TextButton(
                      onPressed: () {
                        _login();
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
