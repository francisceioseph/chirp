import 'package:chirp/app/routes.dart';
import 'package:chirp/app/widgets/screens/home/widgets/molecules/settings_tile.dart';
import 'package:chirp/app/widgets/screens/home/widgets/organisms/chirp_user_control_tile.dart';
import 'package:chirp/config/dependency_manager.dart';
import 'package:chirp/domain/entities/chirp_member.dart';
import 'package:chirp/domain/entities/identity.dart';
import 'package:flutter/material.dart';

class TabSettings extends StatelessWidget {
  const TabSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ChirpUserControlTile(),

        const Divider(indent: 16, endIndent: 16),

        SettingsTile(
          icon: Icons.palette_outlined,
          title: "Temas",
          subtitle: "Mude as cores e a alma do app",
          onTap: () => Navigator.pushNamed(context, ChirpRoutes.themes),
        ),
        SettingsTile(
          icon: Icons.qr_code_2_rounded,
          title: "Meu QR Chirp",
          subtitle: "Mostre seu código para novos amigos",
          onTap: () {
            final identity = getIt<Identity>();
            Navigator.pushNamed(
              context,
              ChirpRoutes.chirpQR,
              arguments: ChirpMember.fromIdentity(identity),
            );
          },
        ),
        SettingsTile(
          icon: Icons.info_outline,
          title: "Sobre",
          subtitle: "ChirpTalk v1.0.0 - 2026",
          onTap: () {},
        ),
      ],
    );
  }
}
