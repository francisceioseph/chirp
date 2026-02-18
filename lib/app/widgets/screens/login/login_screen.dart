import 'package:chirp/app/widgets/screens/login/widgets/atoms/login_header.dart';
import 'package:chirp/app/widgets/screens/login/widgets/molecules/login_form.dart';
import 'package:chirp/config/service_locator.dart';
import 'package:chirp/infrastructure/services/identity_service.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _handleLogin({required String name, required String email}) async {
    try {
      final identityService = getIt<IdentityService>();

      final newIdentity = await identityService.signIn(
        nickname: name,
        email: email,
      );

      await configureSession(newIdentity);

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao entrar no bando: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Opacity(
            opacity: 0.02,
            child: Image.asset(
              'assets/images/stardust.png',
              repeat: ImageRepeat.repeat,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoginHeader(),
                  const SizedBox(height: 40),
                  LoginForm(onSubmit: _handleLogin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
