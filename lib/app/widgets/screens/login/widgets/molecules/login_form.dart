import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/widgets/screens/login/widgets/atoms/login_button.dart';
import 'package:chirp/app/widgets/screens/login/widgets/atoms/login_field.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  final void Function({required String name, required String email}) onSubmit;

  const LoginForm({super.key, required this.onSubmit});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(name: _nameController.text, email: _emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final panelTheme = theme.extension<ChirpPanelTheme>();
    final isFlat = panelTheme?.blurSigma == 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isFlat
            ? colorScheme.surface
            : colorScheme.surface.withValues(alpha: 0.5),

        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            LoginField(
              controller: _nameController,
              label: "Nickname",
              icon: Icons.alternate_email_rounded,
              hint: "Como o bando te chamará?",
            ),
            const SizedBox(height: 20),
            LoginField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              hint: "seu@email.com",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            LoginButton(onPressed: _handleLogin),
          ],
        ),
      ),
    );
  }
}
