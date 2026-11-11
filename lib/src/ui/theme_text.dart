// lib/src/ui/theme_text.dart
//
// O nome de cada tema, para a escolha e o leitor de tela.
import '../../l10n/l10n.dart';

String themeName(ChirpLocalizations l10n, String id) => switch (id) {
  'wild-grey' => l10n.themeWildGrey,
  'skylight' => l10n.themeSkylight,
  'old-days' => l10n.themeOldDays,
  'human' => l10n.themeHuman,
  'symbian' => l10n.themeSymbian,
  'foundation' => l10n.themeFoundation,
  'mighty-cats' => l10n.themeMightyCats,
  _ => l10n.themeLutino,
};
