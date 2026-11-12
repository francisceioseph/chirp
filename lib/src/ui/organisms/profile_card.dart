// lib/src/ui/organisms/profile_card.dart
//
// O perfil deste aparelho: o avatar, o nome (com o botão de trocar) e a chave.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../molecules/fingerprint_text.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile, this.onRename});

  final Profile profile;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IdentityAvatar(seed: profile.avatarSeed, size: 88),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.displayName,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (onRename != null)
                  IconButton(
                    tooltip: l10n.renameTooltip,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onRename,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.profileKeyLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            FingerprintText(fingerprint: profile.fingerprint),
            const SizedBox(height: 8),
            Text(
              l10n.profileKeyHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
