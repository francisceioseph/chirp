// lib/src/ui/pages/contact_page.dart
//
// Um contato: o avatar, o nome, o número de segurança, o "marcar como verificado"
// e por onde ele foi alcançado.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../application/contacts_controller.dart';
import '../../core/chirp_core.dart';
import '../atoms/identity_avatar.dart';
import '../atoms/panel_text.dart';
import '../molecules/fingerprint_text.dart';
import '../reach_text.dart';
import '../templates/centered_panel.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({
    super.key,
    required this.controller,
    required this.contactId,
    this.onClose,
  });

  final ContactsController controller;
  final int contactId;

  /// No painel ao lado, o botão de fechar (por cima, é o voltar).
  final VoidCallback? onClose;

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  String? _safetyNumber;

  /// Quem vê a minha foto: no modo "só os marcados", a chave deste contato aparece.
  PhotoVisibility? _visibility;

  @override
  void initState() {
    super.initState();
    widget.controller.store
        .profile()
        .then((profile) {
          if (mounted) setState(() => _visibility = profile?.photoVisibility);
        })
        .catchError((Object _) {});
    widget.controller
        .safetyNumber(widget.contactId)
        .then((number) {
          if (mounted) setState(() => _safetyNumber = number);
        })
        .catchError((Object _) {});
  }

  Widget? _close(BuildContext context) => switch (widget.onClose) {
    final close? => IconButton(
      tooltip: context.l10n.close,
      onPressed: close,
      icon: const Icon(Icons.close),
    ),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final contact = widget.controller.byId(widget.contactId);
        if (contact == null) {
          return Scaffold(appBar: AppBar(leading: _close(context)));
        }
        final name = contact.displayName.isEmpty
            ? l10n.contactUnnamed
            : contact.displayName;
        final number = _safetyNumber;
        return CenteredPanel(
          appBar: AppBar(leading: _close(context), title: Text(name)),
          children: [
            Center(
              child: IdentityAvatar(
                seed: contact.avatarSeed,
                size: 88,
                photo: contact.photo,
              ),
            ),
            const SizedBox(height: 12),
            PanelTitle(name),
            if (!contact.established) ...[
              const SizedBox(height: 8),
              PanelBody(l10n.contactPending),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.safetyNumberTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (number == null)
              const Center(child: CircularProgressIndicator())
            else
              FingerprintText(fingerprint: number, perLine: 4),
            const SizedBox(height: 8),
            PanelBody(l10n.safetyNumberHelp(name)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l10n.markVerified),
              secondary: Icon(
                contact.verified ? Icons.verified_user : Icons.shield_outlined,
                color: contact.verified
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              value: contact.verified,
              onChanged: (value) =>
                  widget.controller.setVerified(contact.id, verified: value),
            ),
            if (contact.established && _visibility == PhotoVisibility.chosen)
              SwitchListTile(
                title: Text(l10n.photoAllowed),
                subtitle: Text(l10n.photoAllowedHelp),
                secondary: const Icon(Icons.account_circle_outlined),
                value: contact.photoAllowed,
                onChanged: (value) => widget.controller.setPhotoAllowed(
                  contact.id,
                  allowed: value,
                ),
              ),
            if (contact.established)
              ListTile(
                leading: Icon(reachIcon(contact.reach)),
                title: Text(l10n.reachTitle),
                subtitle: Text(reachText(l10n, contact.reach)),
              ),
            if (contact.reach == ContactReach.unreachable)
              PanelBody(unreachableText(l10n, widget.controller.network)),
          ],
        );
      },
    );
  }
}
