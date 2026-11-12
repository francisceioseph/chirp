// lib/src/ui/atoms/reach_avatar.dart
//
// O avatar com o anel de alcance, como a presença dos mensageiros dos anos 2000: verde
// quando o contato está ao alcance agora (rede local, internet, retransmissor ou
// Bluetooth), discreto quando não. Decorativo: quem lê a tela ouve o alcance no texto ao lado.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/chirp_core.dart';
import '../theme/chirp_style.dart';
import 'identity_avatar.dart';

/// O contato está ao alcance agora.
bool isReachable(ContactReach reach) => switch (reach) {
  ContactReach.lan ||
  ContactReach.direct ||
  ContactReach.relay ||
  ContactReach.bluetooth => true,
  ContactReach.unknown || ContactReach.unreachable => false,
};

class ReachAvatar extends StatelessWidget {
  const ReachAvatar({
    super.key,
    required this.seed,
    this.reach,
    this.size = 48,
    this.photo,
  });

  final int seed;

  /// A foto do perfil, quando há uma.
  final Uint8List? photo;

  /// Sem alcance (o meu próprio avatar), o anel é o de quem está ao alcance.
  final ContactReach? reach;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reach = this.reach;
    final ring = reach == null || isReachable(reach)
        ? ChirpStyle.of(context).reachable
        : scheme.outlineVariant;
    final gap = size >= 64 ? 3.0 : 2.0;
    final width = size >= 64 ? 3.0 : 2.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(gap + width),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: width),
      ),
      child: IdentityAvatar(
        seed: seed,
        size: size - 2 * (gap + width),
        photo: photo,
      ),
    );
  }
}
