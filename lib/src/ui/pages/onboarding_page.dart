// lib/src/ui/pages/onboarding_page.dart
//
// O perfil novo: o que o Chirp promete e o nome. A identidade (a chave) nasce junto,
// no núcleo, e o avatar sai dela.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/chirp_mark.dart';
import '../atoms/panel_text.dart';
import '../failure_text.dart';
import '../molecules/name_field.dart';
import '../templates/centered_panel.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onCreate,
    this.failure,
    this.busy = false,
  });

  final ValueChanged<String> onCreate;
  final CoreFailure? failure;
  final bool busy;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ready => _name.text.trim().isNotEmpty && !widget.busy;

  void _submit() {
    if (_ready) widget.onCreate(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = widget.failure;
    return CenteredPanel(
      children: [
        const Center(child: ChirpMark(size: 80)),
        const SizedBox(height: 24),
        PanelTitle(l10n.welcomeTitle),
        const SizedBox(height: 12),
        PanelBody(l10n.welcomeBody),
        const SizedBox(height: 32),
        NameField(
          controller: _name,
          autofocus: true,
          errorText: failure == null ? null : failureText(l10n, failure),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _ready ? _submit : null,
          child: Text(l10n.onboardingCreate),
        ),
      ],
    );
  }
}
