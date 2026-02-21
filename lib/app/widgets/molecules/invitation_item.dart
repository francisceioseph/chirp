import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/domain/models/chirp_packet.dart';
import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InvitationItem extends StatelessWidget {
  final ChirpRequestPacket req;

  const InvitationItem({super.key, required this.req});

  String get _avatarUrl =>
      "https://api.dicebear.com/7.x/adventurer/png?seed=${req.fromName}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final panelTheme = theme.extension<ChirpPanelTheme>();

    final baseRadius =
        panelTheme?.decoration?.borderRadius
            ?.resolve(Directionality.of(context))
            .topLeft
            .x ??
        12.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(baseRadius / 1.5),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(_avatarUrl),
            ),
          ),
          title: Tooltip(
            message: req.fromName,
            child: Text(
              req.fromName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(
            "quer voar no seu bando",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          trailing: _buildActions(context),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final friendshipCtrl = context.read<FriendshipController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.check_rounded,
          color: Colors.green,
          onPressed: () => friendshipCtrl.acceptFriendshipRequest(req),
          tooltip: "Aceitar",
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.close_rounded,
          color: colorScheme.error,
          onPressed: () {
            // Lógica de recusar
          },
          tooltip: "Recusar",
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }
}
