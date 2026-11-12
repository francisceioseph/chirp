// lib/src/ui/pages/profile_page.dart
//
// O perfil deste aparelho: o cartão com a chave, a privacidade das conversas, a
// rede, a aparência e a versão do núcleo.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../application/appearance_controller.dart';
import '../../core/chirp_core.dart';
import '../../platform/background.dart';
import '../molecules/core_status_chip.dart';
import '../organisms/appearance_card.dart';
import '../organisms/background_card.dart';
import '../organisms/chat_settings_card.dart';
import '../organisms/network_card.dart';
import '../organisms/notifications_card.dart';
import '../organisms/profile_card.dart';
import '../templates/centered_panel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.info,
    required this.onRename,
    this.store,
    this.appearance,
  });

  final Profile profile;
  final CoreInfo? info;
  final VoidCallback onRename;

  /// O banco aberto, para os ajustes das conversas.
  final ProfileStore? store;

  /// A aparência do app, para escolher o tema.
  final AppearanceController? appearance;

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
          const SizedBox(height: 16),
          NotificationsCard(store: store),
          const SizedBox(height: 16),
          if (BackgroundScope.of(context).supported) ...[
            BackgroundCard(store: store),
            const SizedBox(height: 16),
          ],
          NetworkCard(store: store),
        ],
        if (appearance case final appearance?) ...[
          const SizedBox(height: 16),
          AppearanceCard(controller: appearance),
        ],
        const SizedBox(height: 24),
        Center(child: CoreStatusChip(info: info)),
      ],
    );
  }
}
