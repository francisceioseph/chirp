import 'package:chirp/app/controllers/chat_controller.dart';
import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/widgets/atoms/chirp_section_header.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/empty_state.dart';
import 'package:chirp/app/widgets/screens/home/widgets/molecules/friend_list_tile.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:flutter/material.dart';

class FriendList extends StatelessWidget {
  const FriendList({super.key});

  @override
  Widget build(BuildContext context) {
    final friendshipCtrl = getIt<FriendshipController>();
    final chatController = getIt<ChatController>();

    return ListenableBuilder(
      listenable: friendshipCtrl,
      builder: (context, _) {
        final groups = friendshipCtrl.groupedFriends;
        final keys = groups.keys.toList();

        if (keys.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            text: "Nenhum amigo ainda",
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            for (var char in keys) ...[
              ChirpSectionHeader(title: char),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final tiel = groups[char]![index];

                  return FriendListTile(
                    tiel: tiel,
                    onActionTap: () =>
                        chatController.openOrCreateConversation(tiel),
                  );
                }, childCount: groups[char]!.length),
              ),
            ],
          ],
        );
      },
    );
  }
}
