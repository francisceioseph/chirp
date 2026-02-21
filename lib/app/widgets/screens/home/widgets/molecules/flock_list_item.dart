import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/tiel_status_badge.dart';
import 'package:flutter/material.dart';

class FlockListItem extends StatelessWidget {
  final Conversation conversation;
  final String? activeChatId;
  final void Function() onTap;
  final void Function() onAddFriendshipTap;

  String get avatarUrl => conversation.avatar;

  const FlockListItem({
    super.key,
    required this.conversation,
    required this.activeChatId,
    required this.onTap,
    required this.onAddFriendshipTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = activeChatId == conversation.id;

    final panelTheme = theme.extension<ChirpPanelTheme>();
    final radius =
        panelTheme?.decoration?.borderRadius
            ?.resolve(Directionality.of(context))
            .topLeft
            .x ??
        12.0;

    // TODO: ADD REAL BADGECOLOR LATER
    final badgeColor = Colors.grey; //conversation.getStatusColor(colorScheme);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: panelTheme?.margin == EdgeInsets.zero ? 4 : 8,
      ),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(radius / 2),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(radius / 2),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: _buildAvatar(badgeColor),
            title: Tooltip(
              message: conversation.title,
              child: Text(
                conversation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ),
            // TODO: ADD TIEL STATUS TEXT LATER
            // subtitle: Text(
            //   conversation.statusText,
            //   maxLines: 1,
            //   overflow: TextOverflow.ellipsis,
            //   style: theme.textTheme.bodySmall?.copyWith(
            //     color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            //   ),
            // ),
            trailing: _buildTrailingAction(context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color badgeColor) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: NetworkImage(conversation.avatar),
        ),
        if (conversation is Tiel)
          Positioned(
            bottom: -2,
            right: -2,
            child: TielStatusBadge(
              badgeColor: badgeColor,
              status: (conversation as Tiel).status,
            ),
          ),
      ],
    );
  }

  Widget? _buildTrailingAction(BuildContext context, ThemeData theme) {
    if (conversation is! Tiel) {
      return null;
    }

    final tiel = conversation as Tiel;

    return switch (tiel.status) {
      TielStatus.discovered => IconButton(
        onPressed: onAddFriendshipTap,
        icon: Icon(Icons.person_add_alt_1_rounded),
        tooltip: "Solicitar Amizade",
      ),

      TielStatus.pending => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.orangeAccent),
        ),
      ),

      TielStatus.connected => Icon(
        Icons.chat_bubble_outline_rounded,
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
        size: 20,
      ),

      _ => null,
    };
  }
}
