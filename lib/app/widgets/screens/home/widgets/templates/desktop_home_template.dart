import 'package:chirp/app/widgets/molecules/stacked_orbs.dart';
import 'package:chirp/app/widgets/organisms/chirp_app_bar.dart';
import 'package:chirp/app/widgets/organisms/notification_drawer.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/chat_panel.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/flock_panel.dart';
import 'package:flutter/material.dart';

class DesktopHomeTemplate extends StatelessWidget {
  const DesktopHomeTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChirpAppBar(),
      endDrawer: const NotificationsDrawer(),
      body: Stack(
        children: [
          const StackedOrbs(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: FlockPanel()),
                  const SizedBox(width: 16),
                  const Expanded(flex: 7, child: ChatPanel()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
