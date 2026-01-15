import 'package:chirp/controllers/chirp_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChirpController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Badge(
            isLabelVisible: controller.notificationCount > 0,
            label: Text(controller.notificationCount.toString()),
            backgroundColor: Colors.redAccent,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        );
      },
    );
  }
}
