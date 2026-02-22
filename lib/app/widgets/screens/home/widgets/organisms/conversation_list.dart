import 'package:chirp/app/controllers/chat_controller.dart';
import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/empty_state.dart';
import 'package:chirp/app/widgets/screens/home/widgets/molecules/conversation_list_tile.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:flutter/material.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelTheme = theme.extension<ChirpPanelTheme>();
    final ctrl = getIt<ChatController>();

    final bool showDivider =
        panelTheme?.blurSigma != null && panelTheme!.blurSigma! > 0;

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final conversations = ctrl.conversations;

        if (conversations.isEmpty) {
          return EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            text: "Nenhum pio por aqui...",
          );
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: panelTheme?.margin == EdgeInsets.zero ? 0 : 8,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: conversations.length,
            separatorBuilder: (context, index) {
              if (!showDivider) return const SizedBox(height: 4);
              return Divider(
                height: 1,
                indent: 72, // Alinhado com o início do texto após o avatar
                endIndent: 16,
                thickness: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              );
            },
            itemBuilder: (context, index) {
              final conversation = conversations[index];

              return ConversationListTile(
                conversation: conversation,
                onTap: () {
                  ctrl.activeConversationId = conversation.id;
                },
              );
            },
          ),
        );
      },
    );
  }
}
