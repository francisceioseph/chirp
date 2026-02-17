import 'package:chirp/app/widgets/organisms/chirp_app_bar.dart';
import 'package:chirp/app/widgets/atoms/resizable_sidebar.dart';
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ResizableSidebar(
                    minWidth: 150,
                    initialWidth: 280,
                    maxWidth: 400,
                    child: const FlockPanel(),
                  ),
                  const SizedBox(width: 8),
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
