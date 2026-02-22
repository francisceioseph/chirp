import 'package:chirp/app/routes.dart';
import 'package:chirp/domain/entities/chirp_member.dart';
import 'package:flutter/material.dart';
import 'package:chirp/app/widgets/templates/profile_view_template.dart';

class ProfileScreen extends StatelessWidget {
  final ChirpMember member;

  const ProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final finalImageUrl =
        member.avatar ??
        "https://api.dicebear.com/7.x/adventurer/png?seed=${member.name}";

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          "Perfil",
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: EdgeInsets.only(top: 24),
        child: ProfileViewTemplate(
          id: member.id,
          name: member.name,
          imageUrl: finalImageUrl,
          actions: _buildContextualActions(context),
        ),
      ),
    );
  }

  List<Widget> _buildContextualActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text("Meu QR Chirp"),
        onPressed: () {
          Navigator.pushNamed(context, ChirpRoutes.chirpQR, arguments: member);
        },
      ),

      SizedBox(height: 16),

      OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text("Enviar um Pio"),
      ),
    ];
  }
}
