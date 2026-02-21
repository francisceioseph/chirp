import 'package:chirp/app/widgets/screens/home/widgets/organisms/nearby_tiels_list.dart';
import 'package:flutter/material.dart';

class FlockPanel extends StatelessWidget {
  const FlockPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Conversas'),
                  ],
                ),
              ),

              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radar, size: 18),
                    SizedBox(width: 8),
                    Text('No Radar'),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [const Placeholder(), const NearbyTielsList()],
            ),
          ),
        ],
      ),
    );
  }
}
