// lib/src/ui/pages/home_page.dart
//
// A tela da fase 1: o perfil pronto, com a chave. A lista de conversas toma o lugar na
// fase 3.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/panel_text.dart';
import '../molecules/core_status_chip.dart';
import '../organisms/profile_card.dart';
import '../templates/centered_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({
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
      appBar: AppBar(title: Text(l10n.appName), centerTitle: true),
      children: [
        ProfileCard(profile: profile, onRename: onRename),
        const SizedBox(height: 24),
        PanelBody(l10n.homeNextPhase),
        const SizedBox(height: 16),
        Center(child: CoreStatusChip(info: info)),
      ],
    );
  }
}
