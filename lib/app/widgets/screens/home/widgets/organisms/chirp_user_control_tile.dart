import 'package:chirp/app/routes.dart';
import 'package:chirp/app/widgets/atoms/chirp_avatar.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:chirp/domain/entities/chirp_member.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:flutter/material.dart';

class ChirpUserControlTile extends StatelessWidget {
  const ChirpUserControlTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final identity = getIt<Identity>();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildAvatar(context, identity),
      title: _buildTitle(theme, identity.name),
      subtitle: _buildSubtitle(theme, colorScheme),
      trailing: _SettingsMenu(colorScheme: colorScheme),
    );
  }

  Widget _buildAvatar(BuildContext context, Identity me) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pushNamed(
          context,
          ChirpRoutes.profile,
          arguments: ChirpMember.fromIdentity(me),
        );
      },
      child: ChirpAvatar(
        name: me.name,
        imageUrl: "https://api.dicebear.com/7.x/adventurer/png?seed=${me.name}",
        radius: 18,
        heroTag: 'profile_avatar_${me.id}',
        badge: const CircleAvatar(
          radius: 5,
          backgroundColor: Colors.greenAccent,
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, String name) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle(ThemeData theme, ColorScheme colorScheme) {
    return Text(
      "No ninho",
      style: theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SettingsMenu extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SettingsMenu({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final identity = getIt<Identity>();

    return MenuAnchor(
      builder: (context, controller, child) => IconButton(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.settings_rounded, size: 20),
        color: colorScheme.primary,
        tooltip: "Configurações",
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.palette_outlined),
          onPressed: () {},
          child: const Text("Temas"),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline),
          onPressed: () {
            Navigator.pushNamed(
              context,
              ChirpRoutes.profile,
              arguments: ChirpMember.fromIdentity(identity),
            );
          },
          child: const Text("Perfil"),
        ),
        const MenuItemButton(
          leadingIcon: Icon(Icons.info_outline),
          child: Text("Sobre"),
        ),
      ],
    );
  }
}
