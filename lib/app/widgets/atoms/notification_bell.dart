import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  final int notificationCount;

  const NotificationBell({super.key, required this.notificationCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Badge(
        isLabelVisible: notificationCount > 0,
        label: Text(notificationCount.toString()),
        backgroundColor: Colors.redAccent,
        child: IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 28),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ),
    );
  }
}
