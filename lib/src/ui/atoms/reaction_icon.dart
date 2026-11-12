// lib/src/ui/atoms/reaction_icon.dart
//
// As reações são um conjunto fixo, desenhado com ícones (a UI não tem emojis). O
// núcleo só conhece o número de cada uma, de 1 a reactionKinds.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';

const _icons = <IconData>[
  Icons.thumb_up,
  Icons.favorite,
  Icons.sentiment_very_satisfied,
  Icons.sentiment_dissatisfied,
  Icons.volunteer_activism,
  Icons.celebration,
];

IconData reactionIcon(int kind) =>
    _icons[(kind - 1).clamp(0, _icons.length - 1)];

String reactionLabel(ChirpLocalizations l10n, int kind) => switch (kind) {
  1 => l10n.reaction1,
  2 => l10n.reaction2,
  3 => l10n.reaction3,
  4 => l10n.reaction4,
  5 => l10n.reaction5,
  _ => l10n.reaction6,
};

/// Uma reação, com o nome para o leitor de tela.
class ReactionIcon extends StatelessWidget {
  const ReactionIcon({
    super.key,
    required this.kind,
    this.size = 18,
    this.color,
  });

  final int kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    reactionIcon(kind),
    size: size,
    color: color ?? Theme.of(context).colorScheme.primary,
    semanticLabel: reactionLabel(context.l10n, kind),
  );
}
