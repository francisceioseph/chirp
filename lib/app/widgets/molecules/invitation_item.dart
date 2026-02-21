import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:flutter/material.dart';

class InvitationItem extends StatelessWidget {
  final String senderName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const InvitationItem({
    super.key,
    required this.senderName,
    required this.onAccept,
    required this.onReject,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(radius / 1.5),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.only(
            left: 12,
            right: 6,
            top: 4,
            bottom: 4,
          ),
          leading: _buildAvatar(colorScheme),
          title: Text(
            senderName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            "Quer pousar no bando",
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onAccept,
                icon: const Icon(Icons.check_circle_outline_rounded),
                color: Colors.greenAccent.shade700,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.close_rounded),
                color: colorScheme.error.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            senderName.isNotEmpty ? senderName[0].toUpperCase() : "?",
            style: TextStyle(color: colorScheme.primary, fontSize: 14),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
            child: const Icon(Icons.mail, size: 8, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
