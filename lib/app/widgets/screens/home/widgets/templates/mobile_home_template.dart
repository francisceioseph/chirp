import 'package:chirp/app/widgets/atoms/chirp_panel.dart';
import 'package:chirp/app/widgets/organisms/chirp_app_bar.dart';
import 'package:chirp/app/widgets/organisms/notification_drawer.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/tab_conversations.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/tab_friends.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/tab_settings.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/tab_radar.dart';
import 'package:flutter/material.dart';

class MobileHomeTemplate extends StatefulWidget {
  const MobileHomeTemplate({super.key});

  @override
  State<MobileHomeTemplate> createState() => _MobileHomeTemplateState();
}

class _MobileHomeTemplateState extends State<MobileHomeTemplate> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const TabConversations(),
    const TabFriends(),
    const TabRadar(),
    const TabSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChirpAppBar(),
      endDrawer: const NotificationsDrawer(),
      body: Stack(children: [ChirpPanel(child: _tabs[_currentIndex])]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Conversas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Amigos",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Radar"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
        ],
      ),
    );
  }
}
