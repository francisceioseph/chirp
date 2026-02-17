import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/widgets/molecules/invitation_item.dart';

class NotificationsDrawer extends StatelessWidget {
  const NotificationsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelTheme = theme.extension<ChirpPanelTheme>();
    final controller = context.watch<ChirpController>();
    final requests = controller.pendingRequests;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final bool isGlass = (panelTheme?.blurSigma ?? 0) > 0;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: isGlass ? 0 : 16,
      width: isMobile ? screenWidth * 0.85 : 400,
      child: Stack(
        children: [
          if (isGlass)
            _buildGlassBackground(panelTheme!, theme)
          else
            _buildFlatBackground(theme),

          if (isGlass)
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
              _buildHeader(context, theme),
              Expanded(
                child: requests.isEmpty
                    ? _buildEmptyState(theme)
                    : _buildRequestList(requests, theme, isGlass),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBackground(ChirpPanelTheme panelTheme, ThemeData theme) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: panelTheme.blurSigma!,
          sigmaY: panelTheme.blurSigma!,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlatBackground(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            "Pios de Amizade",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Text(
          "Ninguém cantando por aqui...",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(List requests, ThemeData theme, bool isGlass) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) => InvitationItem(req: requests[index]),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: theme.colorScheme.onSurface.withValues(
          alpha: isGlass ? 0.05 : 0.1,
        ),
      ),
    );
  }
}
