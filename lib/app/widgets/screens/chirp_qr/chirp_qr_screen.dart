import 'package:chirp/app/widgets/templates/chirp_qr_template.dart';
import 'package:chirp/domain/entities/chirp_member.dart';
import 'package:flutter/material.dart';

class ChirpQRScreen extends StatelessWidget {
  final ChirpMember member;

  const ChirpQRScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Código"),
        centerTitle: true,
        leading: const CloseButton(),
      ),
      body: ChirpQRTemplate(
        id: member.id,
        name: member.name,
        imageUrl:
            member.avatar ??
            "https://api.dicebear.com/7.x/adventurer/png?seed=${member.name}",
      ),
    );
  }
}
