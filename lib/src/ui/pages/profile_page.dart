// lib/src/ui/pages/profile_page.dart
//
// O perfil deste aparelho: o cartão com a chave, e a versão do núcleo.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../molecules/core_status_chip.dart';
import '../organisms/profile_card.dart';
import '../templates/centered_panel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.info,
    required this.onRename,
  });

  final Profile profile;
  final CoreInfo? info;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return CenteredPanel(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      children: [
        ProfileCard(profile: profile, onRename: onRename),
        const SizedBox(height: 24),
        Center(child: CoreStatusChip(info: info)),
      ],
    );
  }
}
