import 'package:chirp/app/controllers/friendship_controller.dart';
import 'package:chirp/app/themes/chirp_panel_theme.dart';
import 'package:chirp/app/widgets/screens/home/widgets/atoms/empty_state.dart';
import 'package:chirp/app/widgets/screens/home/widgets/molecules/nearby_tiel_list_tile.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:flutter/material.dart';

class NearbyTielsList extends StatelessWidget {
  const NearbyTielsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panelTheme = theme.extension<ChirpPanelTheme>();

    final bool showDivider =
        panelTheme?.blurSigma != null && panelTheme!.blurSigma! > 0;

    final ctrl = getIt<FriendshipController>();

    return ListenableBuilder(
      listenable: getIt<FriendshipController>(),
      builder: (context, _) {
        if (ctrl.nearbyTiels.isEmpty) {
          return EmptyState(icon: Icons.radar, text: "Nenhum amigo próximo...");
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
          child: ListView.separated(
            itemCount: ctrl.nearbyTiels.length,
            itemBuilder: (context, index) {
              final tiel = ctrl.nearbyTiels[index];

              return NearbyTielListTile(
                tiel: tiel,
                onActionTap: () => ctrl.requestFriendship(tiel),
              );
            },
            separatorBuilder: (context, index) {
              if (!showDivider) return const SizedBox(height: 4);

              return Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                thickness: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              );
            },
            padding: EdgeInsets.symmetric(
              vertical: panelTheme?.margin == EdgeInsets.zero ? 0 : 8,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
          ),
        );
      },
    );
  }
}
