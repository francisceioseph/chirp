import 'package:chirp/domain/entities/conversation.dart';
import 'package:chirp/domain/entities/tiel.dart';
import 'package:flutter/material.dart';

class FlockList extends StatelessWidget {
  final List<Conversation> conversations;
  final String? activeChatId;
  final void Function(Conversation conversation) onItemTap;
  final void Function(Tiel tiel) onRequestFriendship;

  const FlockList({
    super.key,
    required this.conversations,
    required this.activeChatId,
    required this.onItemTap,
    required this.onRequestFriendship,
  });

  @override
  Widget build(BuildContext context) {
    return Placeholder();

    // TODO: RESTORE THIS LIST LATER
    // final theme = Theme.of(context);
    // final panelTheme = theme.extension<ChirpPanelTheme>();

    // final bool showDivider =
    //     panelTheme?.blurSigma != null && panelTheme!.blurSigma! > 0;

    // return ScrollConfiguration(
    //   behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
    //   child: ListView.separated(
    //     padding: EdgeInsets.symmetric(
    //       vertical: panelTheme?.margin == EdgeInsets.zero ? 0 : 8,
    //     ),
    //     physics: const BouncingScrollPhysics(
    //       parent: AlwaysScrollableScrollPhysics(),
    //     ),
    //     itemCount: conversations.length,
    //     itemBuilder: (context, index) {
    //       final conversation = conversations[index];

    //       return FlockListItem(
    //         key: ValueKey(conversation.id),
    //         conversation: conversation,
    //         activeChatId: activeChatId,
    //         onTap: () => onItemTap(conversation),
    //         onAddFriendshipTap: () {
    //           if (conversation is Tiel) {
    //             onRequestFriendship(conversation);
    //           }
    //         },
    //       );
    //     },
    //     separatorBuilder: (context, index) {
    //       if (!showDivider) return const SizedBox(height: 4);

    //       return Divider(
    //         height: 1,
    //         indent: 16,
    //         endIndent: 16,
    //         thickness: 0.5,
    //         color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
    //       );
    //     },
    //   ),
    // );
  }
}
