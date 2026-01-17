import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/widgets/atoms/chirp_brand_identity.dart';
import 'package:chirp/widgets/atoms/notification_bell.dart';
import 'package:chirp/widgets/molecules/chirp_easter_egg.dart';
import 'package:chirp/widgets/molecules/chirp_secret_touch.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChirpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChirpAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChirpController>(
      builder: (context, controller, _) {
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
              NotificationBell(notificationCount: controller.notificationCount),
            ],
          ),
        );
      },
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
