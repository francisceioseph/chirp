// lib/src/ui/pages/startup_page.dart
//
// A raiz do app nesta fase: desenha o estado do StartupController (a abertura, a
// senha, o perfil novo, o perfil pronto ou o problema) e liga cada tela às intenções.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../application/startup_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/chirp_mark.dart';
import '../organisms/erase_dialog.dart';
import '../organisms/rename_dialog.dart';
import '../templates/centered_panel.dart';
import 'contacts_page.dart';
import 'onboarding_page.dart';
import 'passphrase_page.dart';
import 'problem_page.dart';
import 'profile_page.dart';

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
          StartupReady(:final profile) => _Ready(
            controller: controller,
            profile: profile,
          ),
        };
      },
    );
  }
}

/// O app pronto: os contatos, com o controller deles vivo enquanto o banco estiver
/// aberto.
class _Ready extends StatefulWidget {
  const _Ready({required this.controller, required this.profile});

  final StartupController controller;
  final Profile profile;

  @override
  State<_Ready> createState() => _ReadyState();
}

class _ReadyState extends State<_Ready> {
  late final _contacts = ContactsController(widget.controller.store!);

  @override
  void initState() {
    super.initState();
    _contacts.start();
  }

  @override
  void dispose() {
    _contacts.dispose();
    super.dispose();
  }

  void _openProfile(BuildContext context) {
    final startup = widget.controller;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ListenableBuilder(
          listenable: startup,
          builder: (context, _) {
            final state = startup.state;
            if (state is! StartupReady) return const SizedBox.shrink();
            return ProfilePage(
              profile: state.profile,
              info: startup.core.info,
              onRename: () => showRenameDialog(
                context,
                current: state.profile.displayName,
                rename: startup.rename,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ContactsPage(
    controller: _contacts,
    profile: widget.profile,
    onOpenProfile: () => _openProfile(context),
  );
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
