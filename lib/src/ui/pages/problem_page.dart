// lib/src/ui/pages/problem_page.dart
//
// Quando a abertura para: o que houve, em palavras simples, e o que dá para fazer
// (tentar de novo, ou apagar e começar de novo quando os dados não se abrem mais).
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../application/startup_controller.dart';
import '../atoms/panel_text.dart';
import '../atoms/state_icon.dart';
import '../templates/centered_panel.dart';

class ProblemPage extends StatelessWidget {
  const ProblemPage({
    super.key,
    required this.problem,
    required this.onRetry,
    required this.onErase,
    this.busy = false,
  });

  final StartupProblem problem;
  final VoidCallback onRetry;
  final VoidCallback onErase;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, body) = switch (problem) {
      StartupProblem.coreMissing => (
        l10n.coreUnavailable,
        l10n.problemCoreBody,
      ),
      StartupProblem.vaultUnavailable => (
        l10n.problemVaultTitle,
        l10n.problemVaultBody,
      ),
      StartupProblem.keyLost => (
        l10n.problemKeyLostTitle,
        l10n.problemKeyLostBody,
      ),
      StartupProblem.newerStore => (
        l10n.problemNewerTitle,
        l10n.problemNewerBody,
      ),
      StartupProblem.storage => (
        l10n.problemStorageTitle,
        l10n.problemStorageBody,
      ),
    };
    final canRetry = problem != StartupProblem.keyLost;
    final canErase = switch (problem) {
      StartupProblem.keyLost || StartupProblem.storage => true,
      _ => false,
    };
    return CenteredPanel(
      children: [
        Center(
          child: StateIcon(switch (problem) {
            StartupProblem.keyLost => Icons.key_off_outlined,
            StartupProblem.vaultUnavailable =>
              Icons.enhanced_encryption_outlined,
            StartupProblem.newerStore => Icons.update,
            _ => Icons.error_outline,
          }, tone: StateTone.error),
        ),
        const SizedBox(height: 24),
        PanelTitle(title),
        const SizedBox(height: 12),
        PanelBody(body),
        const SizedBox(height: 24),
        if (canRetry)
          FilledButton(
            onPressed: busy ? null : onRetry,
            child: Text(l10n.tryAgain),
          ),
        if (canRetry && canErase) const SizedBox(height: 8),
        if (canErase)
          canRetry
              ? TextButton(
                  onPressed: busy ? null : onErase,
                  child: Text(l10n.eraseEverything),
                )
              : FilledButton.tonal(
                  onPressed: busy ? null : onErase,
                  child: Text(l10n.eraseEverything),
                ),
      ],
    );
  }
}
