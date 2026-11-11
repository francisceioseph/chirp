// lib/src/ui/pages/startup_page.dart
//
// A raiz do app nesta fase: desenha o estado do StartupController (a abertura, a
// senha, o perfil novo, o perfil pronto ou o problema) e liga cada tela às intenções.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../application/startup_controller.dart';
import '../atoms/chirp_mark.dart';
import '../organisms/erase_dialog.dart';
import '../organisms/rename_dialog.dart';
import '../templates/centered_panel.dart';
import 'home_page.dart';
import 'onboarding_page.dart';
import 'passphrase_page.dart';
import 'problem_page.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({super.key, required this.controller});

  final StartupController controller;

  Future<void> _erase(BuildContext context) async {
    if (await confirmErase(context)) await controller.wipeAndRestart();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final busy = controller.busy;
        return switch (controller.state) {
          StartupLoading() => const _LoadingPage(),
          StartupProblemState(:final problem) => ProblemPage(
            problem: problem,
            busy: busy,
            onRetry: controller.start,
            onErase: () => _erase(context),
          ),
          StartupNeedsPassphrase(:final creating, :final failure) =>
            PassphrasePage(
              key: ValueKey(creating),
              creating: creating,
              minChars: controller.core.minPassphraseChars,
              failure: failure,
              busy: busy,
              onSubmit: controller.submitPassphrase,
              onErase: creating ? null : () => _erase(context),
            ),
          StartupOnboarding(:final failure) => OnboardingPage(
            failure: failure,
            busy: busy,
            onCreate: controller.createProfile,
          ),
          StartupReady(:final profile) => HomePage(
            profile: profile,
            info: controller.core.info,
            onRename: () => showRenameDialog(
              context,
              current: profile.displayName,
              rename: controller.rename,
            ),
          ),
        };
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return CenteredPanel(
      children: [
        const Center(child: ChirpMark(size: 72)),
        const SizedBox(height: 24),
        Center(
          child: CircularProgressIndicator(
            semanticsLabel: context.l10n.loading,
          ),
        ),
      ],
    );
  }
}
