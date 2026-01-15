import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/organisms/chirp_app_bar.dart';
import 'package:chirp/widgets/organisms/notification_drawer.dart';
import 'package:chirp/widgets/molecules/stacked_orbs.dart';
import 'package:chirp/widgets/screens/home/widgets/chat_panel.dart';
import 'package:chirp/widgets/screens/home/widgets/flock_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: ChirpAppBar(),
      backgroundColor: colorScheme.surface,
      endDrawer: NotificationsDrawer(),
      body: Stack(
        children: [
          StackedOrbs(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return _buildMobileLayout();
                }

                return _buildDesktopLayout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(flex: 3, child: FlockPanel()),
          SizedBox(width: 16),
          Expanded(flex: 7, child: ChatPanel()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Consumer<ChirpController>(
      builder: (context, controller, child) {
        if (controller.activeChatId != null) {
          return const ChatPanel();
        }

        // Caso contrário, mostramos apenas a lista do bando
        return const FlockPanel();
      },
    );
  }
}
