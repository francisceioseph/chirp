import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/widgets/molecules/invitation_item.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:chirp/utils/app_logger.dart';
import 'package:flutter/material.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendshipCtrl = getIt<FriendshipController>();
    final requests = friendshipCtrl.pendingRequests;

    if (requests.isEmpty) {
      return const Center(
        child: Opacity(
          opacity: 0.5,
          child: Text(
            "Ninguém cantando por aqui...",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: friendshipCtrl,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];

            return InvitationItem(
              senderName: req.fromName,
              onAccept: () => friendshipCtrl.acceptFriendshipRequest(req),
              onReject: () => log.d("Recusou o pio de ${req.fromName}"),
            );
          },
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        );
      },
    );
  }
}
