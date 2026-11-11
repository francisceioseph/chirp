// lib/src/ui/pages/welcome_page.dart
//
// A tela da fase 0: diz o que o Chirp promete e mostra se o núcleo em Rust abriu.
// Dá lugar ao onboarding na fase 1.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/chirp_mark.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.core});

  final ChirpCore core;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final info = core.info;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ChirpMark(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.welcomeBody,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.foundationNote,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _CoreStatus(info: info),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoreStatus extends StatelessWidget {
  const _CoreStatus({required this.info});

  final CoreInfo? info;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final info = this.info;
    if (info == null) {
      return Chip(
        avatar: Icon(Icons.error_outline, color: scheme.error),
        label: Text(l10n.coreUnavailable),
      );
    }
    return Chip(
      avatar: Icon(Icons.verified_user_outlined, color: scheme.primary),
      label: Text(l10n.coreVersion(info.version, info.protocol)),
    );
  }
}
