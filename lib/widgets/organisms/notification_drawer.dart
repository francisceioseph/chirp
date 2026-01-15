import 'dart:ui';

import 'package:chirp/widgets/molecules/invitation_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chirp/controllers/chirp_controller.dart';

class NotificationsDrawer extends StatelessWidget {
  const NotificationsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ChirpController>();
    final requests = controller.pendingRequests;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Drawer(
      backgroundColor: Colors.transparent,
      width: isMobile ? screenWidth * 0.8 : 400,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12.0),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.15),
                  border: Border(
                    left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/stardust.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    Text(
                      "Pios de Amizade",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (requests.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      "Ninguém cantando por aqui ainda...",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: requests.length,
                    itemBuilder: (context, index) =>
                        InvitationItem(req: requests[index]),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
