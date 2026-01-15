import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/molecules/chirp_header_title.dart';
import 'package:chirp/widgets/atoms/notification_bell.dart';
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
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ChirpHeaderTitle()),
              NotificationBell(notificationCount: controller.notificationCount),
            ],
          ),
        );
      },
    );
  }
}
