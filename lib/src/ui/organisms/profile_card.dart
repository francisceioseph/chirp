// lib/src/ui/organisms/profile_card.dart
//
// O perfil deste aparelho: o avatar, o nome (com o botão de trocar) e a chave.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/reach_avatar.dart';
import '../molecules/fingerprint_text.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile, this.onRename});

  final Profile profile;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        // Um degradê do tom primário para a superfície: o "cartão de visita".
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer, scheme.surfaceContainerLow],
            stops: const [0, 0.7],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReachAvatar(seed: profile.avatarSeed, size: 104),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName,
                      style: theme.textTheme.headlineSmall,
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 20,
                            color: scheme.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.profileKeyLabel,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FingerprintText(fingerprint: profile.fingerprint),
                      const SizedBox(height: 8),
                      Text(
                        l10n.profileKeyHelp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
