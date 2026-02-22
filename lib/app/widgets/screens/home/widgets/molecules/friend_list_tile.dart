import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/widgets/atoms/chirp_avatar.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/tiel_status_badge.dart';
import 'package:flutter/material.dart';

class FriendListTile extends StatelessWidget {
  final Tiel tiel;
  final void Function() onActionTap;

  const FriendListTile({
    super.key,
    required this.tiel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final panelTheme = theme.extension<ChirpPanelTheme>();

    final radius =
        panelTheme?.decoration?.borderRadius
            ?.resolve(Directionality.of(context))
            .topLeft
            .x ??
        12.0;

    final bool isOffline = tiel.status == TielStatus.away;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: panelTheme?.margin == EdgeInsets.zero ? 4 : 8,
        vertical: 2,
      ),
      child: Opacity(
        opacity: isOffline ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(radius / 1.5),
          ),
          child: ListTile(
            onTap: onActionTap, // Facilitando o toque em toda a área
            contentPadding: const EdgeInsets.only(left: 12, right: 4),
            leading: ChirpAvatar(
              imageUrl: tiel.avatar,
              name: tiel.name,
              badge: TielStatusBadge(
                badgeColor: tiel.getStatusColor(colorScheme),
                status: tiel.status,
              ),
            ),
            title: Text(
              tiel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              tiel.statusText, // Usando o seu switch case da entidade
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            trailing: IconButton(
              onPressed: onActionTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              color: colorScheme.primary,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
              ),
              tooltip: "Iniciar Pio",
            ),
          ),
        ),
      ),
    );
  }
}
