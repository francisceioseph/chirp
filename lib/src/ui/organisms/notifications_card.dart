// lib/src/ui/organisms/notifications_card.dart
//
// O que as notificações mostram (docs/PLANO.md, 7.6): nada, só "Nova mensagem", o
// nome, ou o nome e o texto. Ligar pede a permissão onde o sistema pede.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';
import '../../platform/notifier.dart';

class NotificationsCard extends StatefulWidget {
  const NotificationsCard({super.key, required this.store});

  final ProfileStore store;

  @override
  State<NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<NotificationsCard> {
  NotificationMode? _mode;

  @override
  void initState() {
    super.initState();
    widget.store
        .notificationMode()
        .then((mode) {
          if (mounted) setState(() => _mode = mode);
        })
        .catchError((Object _) {});
  }

  Future<void> _set(NotificationMode? mode) async {
    if (mode == null) return;
    final before = _mode;
    setState(() => _mode = mode);
    try {
      await widget.store.setNotificationMode(mode);
    } on CoreException {
      if (mounted) setState(() => _mode = before);
      return;
    }
    if (mode != NotificationMode.off && mounted) {
      final l10n = context.l10n;
      await NotifierScope.of(
        context,
      )?.init(open: l10n.notificationOpen, channel: l10n.notificationChannel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mode = _mode;
    if (mode == null) return const SizedBox.shrink();
    RadioListTile<NotificationMode> option(
      NotificationMode value,
      String title, [
      String? help,
    ]) => RadioListTile<NotificationMode>(
      value: value,
      title: Text(title),
      subtitle: help == null ? null : Text(help),
    );
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
                  Text(
                    l10n.notificationsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.notificationsHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            RadioGroup<NotificationMode>(
              groupValue: mode,
              onChanged: _set,
              child: Column(
                children: [
                  option(
                    NotificationMode.full,
                    l10n.notifyFull,
                    l10n.notifyFullHelp,
                  ),
                  option(
                    NotificationMode.sender,
                    l10n.notifySender,
                    l10n.notifySenderHelp,
                  ),
                  option(
                    NotificationMode.hidden,
                    l10n.notifyHidden,
                    l10n.notifyHiddenHelp,
                  ),
                  option(NotificationMode.off, l10n.notifyOff),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
