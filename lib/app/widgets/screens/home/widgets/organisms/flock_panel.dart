import 'package:chirp/app/widgets/screens/home/widgets/organisms/chirp_user_control_tile.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/conversation_list.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/friend_list.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/nearby_tiels_list.dart';
import 'package:flutter/material.dart';

class FlockPanel extends StatelessWidget {
  const FlockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              _buildTab(Icons.chat_bubble_outline, 'Conversas'),
              _buildTab(Icons.people_outline, 'Amigos'),
              _buildTab(Icons.radar, 'Radar'),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                const ConversationList(),
                const FriendList(),
                const NearbyTielsList(),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            indent: 32,
            endIndent: 32,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),

          ChirpUserControlTile(),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Crucial: A Row só ocupa o espaço necessário
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}
