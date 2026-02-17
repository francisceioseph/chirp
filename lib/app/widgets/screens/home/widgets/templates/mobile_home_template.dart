import 'package:chirp/app/widgets/atoms/chirp_panel.dart';
import 'package:chirp/app/widgets/organisms/chirp_app_bar.dart';
import 'package:chirp/app/widgets/organisms/notification_drawer.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/flock_tab.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/perch_tab.dart';
import 'package:flutter/material.dart';

class MobileHomeTemplate extends StatefulWidget {
  const MobileHomeTemplate({super.key});

  @override
  State<MobileHomeTemplate> createState() => _MobileHomeTemplateState();
}

class _MobileHomeTemplateState extends State<MobileHomeTemplate> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [const FlockTab(), const PerchTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ChirpAppBar(),
      endDrawer: const NotificationsDrawer(),
      body: Stack(children: [ChirpPanel(child: _tabs[_currentIndex])]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Flock'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perch'),
        ],
      ),
    );
  }
}
