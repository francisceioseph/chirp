import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.flutter_dash_rounded, size: 80, color: colorScheme.primary),
        const SizedBox(height: 16),
        const Text(
          "ChirpTalk",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const Text("O seu bando te espera"),
      ],
    );
  }
}
