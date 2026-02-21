import 'package:chirp/app/widgets/atoms/drawer_background.dart';
import 'package:chirp/app/widgets/molecules/notification_header.dart';
import 'package:chirp/app/widgets/organisms/notification_list.dart';
import 'package:flutter/material.dart';
import 'package:chirp/app/themes/chirp_panel_theme.dart';

class NotificationsDrawer extends StatelessWidget {
  const NotificationsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelTheme = theme.extension<ChirpPanelTheme>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: (panelTheme?.blurSigma ?? 0) > 0 ? 0 : 16,
      width: screenWidth < 800 ? screenWidth * 0.85 : 400,
      child: DrawerBackground(
        panelTheme: panelTheme,
        child: const Column(
          children: [
            NotificationHeader(),
            Expanded(child: NotificationList()),
          ],
        ),
      ),
    );
  }
}
