import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/app/widgets/templates/profile_view_template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PerchTab extends StatelessWidget {
  const PerchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChirpController>();

    return ProfileViewTemplate(
      name: controller.myName,
      id: controller.myId,
      imageUrl:
          "https://api.dicebear.com/7.x/adventurer/png?seed=${controller.myName}",
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.qr_code_2),
          label: const Text("Meu QR Chirp"),
        ),
      ],
    );
  }
}
