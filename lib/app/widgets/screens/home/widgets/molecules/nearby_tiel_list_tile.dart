import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/tiel_status_badge.dart';
import 'package:flutter/material.dart';

class NearbyTielListTile extends StatelessWidget {
  final Tiel tiel;
  final void Function() onActionTap;

  const NearbyTielListTile({
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: panelTheme?.margin == EdgeInsets.zero ? 4 : 8,
        vertical: 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(radius / 1.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 12, right: 4),
          leading: _buildAvatar(colorScheme),
          title: Tooltip(
            message: tiel.name,
            child: Text(
              tiel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          subtitle: Text(
            "Disponível no bando",
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          trailing: _buildActionButton(theme),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: NetworkImage(tiel.avatar),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: TielStatusBadge(
            badgeColor: tiel.getStatusColor(colorScheme),
            status: tiel.status,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (tiel.status) {
        TielStatus.pending => const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        _ => IconButton(
          onPressed: onActionTap,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          color: theme.colorScheme.primary,
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          ),
          tooltip: "Solicitar Amizade",
        ),
      },
    );
  }
}
