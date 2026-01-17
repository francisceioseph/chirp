import 'package:chirp/app/widgets/screens/home/widgets/templates/desktop_home_template.dart';
import 'package:chirp/app/widgets/screens/home/widgets/templates/mobile_home_template.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return const DesktopHomeTemplate();
        } else {
          return const MobileHomeTemplate();
        }
      },
    );
  }
}
