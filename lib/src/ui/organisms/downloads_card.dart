// lib/src/ui/organisms/downloads_card.dart
//
// O baixar sozinho (docs/PLANO.md, 6.7): até que tamanho o arquivo de um contato
// baixa ao chegar, e se só dos contatos verificados. O resto espera o "Baixar".
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';

class DownloadsCard extends StatefulWidget {
  const DownloadsCard({super.key, required this.store});

  final ProfileStore store;

  @override
  State<DownloadsCard> createState() => _DownloadsCardState();
}

class _DownloadsCardState extends State<DownloadsCard> {
  DownloadPolicy? _policy;

  @override
  void initState() {
    super.initState();
    widget.store
        .downloadPolicy()
        .then((policy) {
          if (mounted) setState(() => _policy = policy);
        })
        .catchError((Object _) {});
  }

  Future<void> _set(DownloadPolicy policy) async {
    final before = _policy;
    setState(() => _policy = policy);
    try {
      await widget.store.setDownloadPolicy(policy);
    } on CoreException {
      if (mounted) setState(() => _policy = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final policy = _policy;
    if (policy == null) return const SizedBox.shrink();
    RadioListTile<AutoDownload> option(AutoDownload value, String title) =>
        RadioListTile<AutoDownload>(value: value, title: Text(title));
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.downloadsTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l10n.downloadsHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            RadioGroup<AutoDownload>(
              groupValue: policy.limit,
              onChanged: (limit) {
                if (limit != null) _set(policy.copyWith(limit: limit));
              },
              child: Column(
                children: [
                  option(AutoDownload.large, l10n.autoDownloadLarge),
                  option(AutoDownload.medium, l10n.autoDownloadMedium),
                  option(AutoDownload.small, l10n.autoDownloadSmall),
                  option(AutoDownload.never, l10n.autoDownloadNever),
                ],
              ),
            ),
            if (policy.limit != AutoDownload.never)
              SwitchListTile(
                title: Text(l10n.onlyVerified),
                subtitle: Text(l10n.onlyVerifiedHelp),
                value: policy.onlyVerified,
                onChanged: (on) => _set(policy.copyWith(onlyVerified: on)),
              ),
          ],
        ),
      ),
    );
  }
}
