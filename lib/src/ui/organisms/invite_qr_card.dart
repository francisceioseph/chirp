// lib/src/ui/organisms/invite_qr_card.dart
//
// O meu convite: o QR (frente a frente, e o contato nasce verificado) e o link para
// mandar por outro canal (o contato nasce não verificado). Cada um vale uma vez, por
// 24 horas.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/l10n.dart';
import '../theme/chirp_theme.dart';

class InviteQrCard extends StatelessWidget {
  const InviteQrCard({
    super.key,
    required this.link,
    required this.onNewCode,
    required this.createLink,
  });

  /// O link do convite do QR; nulo enquanto é criado.
  final String? link;
  final VoidCallback onNewCode;

  /// Cria um convite próprio para mandar como link.
  final Future<String> Function() createLink;

  Future<void> _copyLink(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final link = await createLink();
    await Clipboard.setData(ClipboardData(text: link));
    messenger.showSnackBar(SnackBar(content: Text(l10n.inviteLinkCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final link = this.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: qrLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox.square(
              dimension: 200,
              child: link == null
                  ? const Center(child: CircularProgressIndicator())
                  : Semantics(
                      label: l10n.inviteQrLabel,
                      image: true,
                      child: QrImageView(
                        data: link,
                        padding: EdgeInsets.zero,
                        backgroundColor: qrLight,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: qrDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: qrDark,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.inviteQrHelp,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () => _copyLink(context),
          icon: const Icon(Icons.link),
          label: Text(l10n.inviteCopyLink),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onNewCode,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.inviteNewCode),
        ),
      ],
    );
  }
}
