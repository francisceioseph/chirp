// lib/src/ui/molecules/contact_tile.dart
//
// Um contato na lista: o avatar da chave, o nome e o estado (verificado, não
// verificado ou esperando o outro aparelho).
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.contact, this.onTap});

  final Contact contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (icon, status, color) = !contact.established
        ? (Icons.hourglass_top, l10n.contactPending, scheme.onSurfaceVariant)
        : contact.verified
        ? (Icons.verified_user, l10n.contactVerified, scheme.primary)
        : (
            Icons.shield_outlined,
            l10n.contactUnverified,
            scheme.onSurfaceVariant,
          );
    return ListTile(
      leading: IdentityAvatar(seed: contact.avatarSeed, size: 40),
      title: Text(
        contact.displayName.isEmpty ? l10n.contactUnnamed : contact.displayName,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(child: Text(status, overflow: TextOverflow.ellipsis)),
        ],
      ),
      onTap: onTap,
    );
  }
}
