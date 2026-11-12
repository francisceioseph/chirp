// lib/src/ui/organisms/empty_home.dart
//
// O início sem contatos: a calopsita, o que o Chirp é em uma frase e os dois jeitos de
// adicionar alguém (mostrar o meu código, ou usar um link). Os cartões ficam lado a
// lado quando cabem e um sobre o outro numa janela estreita.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../atoms/cockatiel.dart';

class EmptyHome extends StatelessWidget {
  const EmptyHome({super.key, this.onShowCode, this.onUseLink});

  /// Sem eles (a rede não ligou), os cartões não aparecem.
  final VoidCallback? onShowCode;
  final VoidCallback? onUseLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cards = [
      _WayCard(
        icon: Icons.qr_code_2,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        title: l10n.emptyShowCode,
        body: l10n.emptyShowCodeBody,
        onTap: onShowCode,
      ),
      _WayCard(
        icon: Icons.link,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        title: l10n.emptyUseLink,
        body: l10n.emptyUseLinkBody,
        onTap: onUseLink,
      ),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Cockatiel(size: 128),
              const SizedBox(height: 20),
              Text(
                l10n.contactsEmptyTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.contactsEmptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onShowCode != null || onUseLink != null) ...[
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 520
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            cards[0],
                            const SizedBox(height: 12),
                            cards[1],
                          ],
                        ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.emptyPromise,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WayCard extends StatelessWidget {
  const _WayCard({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(height: 12),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
