import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/models/chirp_packet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InvitationItem extends StatelessWidget {
  final ChirpRequestPacket req;

  const InvitationItem({super.key, required this.req});

  String get _avatarUrl =>
      "https://api.dicebear.com/7.x/adventurer/png?seed=${req.fromName}";

  @override
  Widget build(BuildContext context) {
    return Consumer<ChirpController>(
      builder: (context, controller, _) {
        return ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(_avatarUrl)),
          title: Text(req.fromName),
          subtitle: const Text("Quer voar no seu bando"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => controller.acceptFriendship(req),
              ),

              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                onPressed: () {
                  // Opcional: Adicionar lógica para ignorar pedido
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
