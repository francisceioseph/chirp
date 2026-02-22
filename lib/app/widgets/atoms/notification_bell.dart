import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  final int notificationCount;

  const NotificationBell({super.key, required this.notificationCount});

  @override
  Widget build(BuildContext context) {
    final icon = notificationCount > 0
        ? Icons.notifications_active_outlined
        : Icons.notifications_none_outlined;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Badge(
        isLabelVisible: notificationCount > 0,
        label: Text(notificationCount.toString()),
        backgroundColor: Colors.redAccent,
        child: IconButton(
          icon: Icon(icon, size: 28),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ),
    );
  }
}
