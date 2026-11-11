// lib/src/ui/pages/profile_page.dart
//
// O perfil deste aparelho: o cartão com a chave, a privacidade das conversas e a
// versão do núcleo.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../molecules/core_status_chip.dart';
import '../organisms/chat_settings_card.dart';
import '../organisms/profile_card.dart';
import '../templates/centered_panel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.info,
    required this.onRename,
    this.store,
  });

  final Profile profile;
  final CoreInfo? info;
  final VoidCallback onRename;

  /// O banco aberto, para os ajustes das conversas.
  final ProfileStore? store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CenteredPanel(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      children: [
        ProfileCard(profile: profile, onRename: onRename),
        if (store case final store?) ...[
          const SizedBox(height: 16),
          ChatSettingsCard(store: store),
        ],
        const SizedBox(height: 24),
        Center(child: CoreStatusChip(info: info)),
      ],
    );
  }
}
