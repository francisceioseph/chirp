// lib/src/ui/reach_text.dart
//
// Por onde um contato foi alcançado, e por que não foi: o texto depende da rede
// escolhida (só a local, internet sem retransmissor, com retransmissor).
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../core/chirp_core.dart';

String reachText(ChirpLocalizations l10n, ContactReach reach) =>
    switch (reach) {
      ContactReach.unknown => l10n.reachUnknown,
      ContactReach.lan => l10n.reachLan,
      ContactReach.direct => l10n.reachDirect,
      ContactReach.relay => l10n.reachRelay,
      ContactReach.unreachable => l10n.reachUnreachable,
    };

IconData reachIcon(ContactReach reach) => switch (reach) {
  ContactReach.unknown => Icons.help_outline,
  ContactReach.lan => Icons.wifi,
  ContactReach.direct => Icons.public,
  ContactReach.relay => Icons.dns_outlined,
  ContactReach.unreachable => Icons.cloud_off_outlined,
};

/// Por que o contato não foi alcançado, e o que dá para fazer.
String unreachableText(ChirpLocalizations l10n, NetworkSettings network) =>
    !network.internet
    ? l10n.unreachableLocalOnly
    : network.relays.isEmpty
    ? l10n.unreachableNoRelay
    : l10n.unreachableOffline;
