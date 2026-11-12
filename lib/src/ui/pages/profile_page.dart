// lib/src/ui/pages/profile_page.dart
//
// O perfil deste aparelho: o cartão com a chave, a privacidade das conversas, a
// rede, a aparência e a versão do núcleo. Numa janela estreita, uma coluna só; a
// partir de 840 px, como os ajustes de um app de computador: as seções numa lista à
// esquerda e a escolhida à direita.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../application/appearance_controller.dart';
import '../../core/chirp_core.dart';
import '../../platform/background.dart';
import '../molecules/core_status_chip.dart';
import '../organisms/appearance_card.dart';
import '../organisms/background_card.dart';
import '../organisms/chat_settings_card.dart';
import '../organisms/downloads_card.dart';
import '../organisms/mailbox_card.dart';
import '../organisms/network_card.dart';
import '../organisms/notifications_card.dart';
import '../organisms/profile_card.dart';
import '../organisms/profile_photo_card.dart';
import '../templates/centered_panel.dart';
import '../templates/shell_template.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.info,
    required this.onRename,
    this.store,
    this.appearance,
    this.changeProfile,
  });

  final Profile profile;
  final CoreInfo? info;
  final VoidCallback onRename;

  /// O banco aberto, para os ajustes das conversas.
  final ProfileStore? store;

  /// A aparência do app, para escolher o tema.
  final AppearanceController? appearance;

  /// Muda o perfil pelo núcleo (a foto, quem vê); devolve a falha, ou nulo.
  final Future<CoreFailure?> Function(
    Future<Profile> Function(ProfileStore store) change,
  )?
  changeProfile;

  /// As seções, na ordem da lista: o ícone, o nome e o conteúdo.
  List<({IconData icon, String label, Widget child})> _sections(
    BuildContext context,
  ) {
    final l10n = context.l10n;
    final store = this.store;
    final appearance = this.appearance;
    final changeProfile = this.changeProfile;
    return [
      (
        icon: Icons.person_outline,
        label: l10n.profileTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileCard(profile: profile, onRename: onRename),
            const SizedBox(height: 24),
            Center(child: CoreStatusChip(info: info)),
          ],
        ),
      ),
      if (changeProfile != null)
        (
          icon: Icons.account_circle_outlined,
          label: l10n.photoTitle,
          child: ProfilePhotoCard(profile: profile, change: changeProfile),
        ),
      if (store != null) ...[
        (
          icon: Icons.forum_outlined,
          label: l10n.chatSettingsTitle,
          child: ChatSettingsCard(store: store),
        ),
        (
          icon: Icons.notifications_outlined,
          label: l10n.notificationsTitle,
          child: NotificationsCard(store: store),
        ),
        (
          icon: Icons.download_outlined,
          label: l10n.downloadsTitle,
          child: DownloadsCard(store: store),
        ),
        if (BackgroundScope.of(context).supported)
          (
            icon: Icons.nights_stay_outlined,
            label: l10n.backgroundTitle,
            child: BackgroundCard(store: store),
          ),
        (
          icon: Icons.lan_outlined,
          label: l10n.networkTitle,
          child: NetworkCard(store: store),
        ),
        (
          icon: Icons.markunread_mailbox_outlined,
          label: l10n.mailboxTitle,
          child: MailboxCard(store: store),
        ),
      ],
      if (appearance != null)
        (
          icon: Icons.palette_outlined,
          label: l10n.appearanceTitle,
          child: AppearanceCard(controller: appearance),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ShellTemplate.twoColumns) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.profileTitle)),
            body: _Sections(sections: _sections(context)),
          );
        }
        return CenteredPanel(
          appBar: AppBar(title: Text(l10n.profileTitle)),
          children: [
            ProfileCard(profile: profile, onRename: onRename),
            if (changeProfile case final change?) ...[
              const SizedBox(height: 16),
              ProfilePhotoCard(profile: profile, change: change),
            ],
            if (store case final store?) ...[
              const SizedBox(height: 16),
              ChatSettingsCard(store: store),
              const SizedBox(height: 16),
              NotificationsCard(store: store),
              const SizedBox(height: 16),
              DownloadsCard(store: store),
              const SizedBox(height: 16),
              if (BackgroundScope.of(context).supported) ...[
                BackgroundCard(store: store),
                const SizedBox(height: 16),
              ],
              NetworkCard(store: store),
              const SizedBox(height: 16),
              MailboxCard(store: store),
            ],
            if (appearance case final appearance?) ...[
              const SizedBox(height: 16),
              AppearanceCard(controller: appearance),
            ],
            const SizedBox(height: 24),
            Center(child: CoreStatusChip(info: info)),
          ],
        );
      },
    );
  }
}

/// As seções à esquerda e a escolhida à direita, alinhada no topo.
class _Sections extends StatefulWidget {
  const _Sections({required this.sections});

  final List<({IconData icon, String label, Widget child})> sections;

  @override
  State<_Sections> createState() => _SectionsState();
}

class _SectionsState extends State<_Sections> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sections = widget.sections;
    final selected = _selected.clamp(0, sections.length - 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: Material(
            color: scheme.surfaceContainerLow,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                for (final (index, section) in sections.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      selected: index == selected,
                      selectedTileColor: scheme.secondaryContainer,
                      selectedColor: scheme.onSecondaryContainer,
                      shape: const StadiumBorder(),
                      leading: Icon(section.icon),
                      title: Text(section.label),
                      onTap: () => setState(() => _selected = index),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              key: ValueKey(selected),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: sections[selected].child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
