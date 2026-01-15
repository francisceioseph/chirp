import 'package:chirp/widgets/components/app_bar/chirp_header_title.dart';
import 'package:chirp/widgets/components/app_bar/notification_bell.dart';
import 'package:flutter/material.dart';

class ChirpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChirpAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ChirpHeaderTitle()),
          NotificationBell(),
        ],
      ),
    );
  }
}
