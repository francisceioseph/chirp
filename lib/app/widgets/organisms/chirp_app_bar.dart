import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/widgets/atoms/chirp_brand_identity.dart';
import 'package:chirp/app/widgets/atoms/notification_bell.dart';
import 'package:chirp/app/widgets/molecules/chirp_easter_egg.dart';
import 'package:chirp/app/widgets/molecules/chirp_secret_touch.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:flutter/material.dart';

class ChirpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChirpAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    final friendshipCtrl = getIt<FriendshipController>();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).padding.top + 8,
        horizontal: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ChirpSecretTouch(
            onReveal: () => _showEasterEgg(context),
            child: const ChirpBrandIdentity(
              alignment: CrossAxisAlignment.start,
            ),
          ),
          ListenableBuilder(
            listenable: friendshipCtrl,
            builder: (context, _) {
              return NotificationBell(
                notificationCount: friendshipCtrl.notificationCount,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEasterEgg(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        content: const ChirpEasterEgg(),
      ),
    );
  }
}
