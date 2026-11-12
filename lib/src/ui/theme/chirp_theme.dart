// lib/src/ui/theme/chirp_theme.dart
//
// O tema do Chirp: Material 3 a partir de um ChirpThemeSpec. O theme/ é o único lugar
// com cor escrita à mão; os widgets pegam tudo do colorScheme e do ChirpStyle (o
// privacy_test confere).
import 'package:material_ui/material_ui.dart';

import 'chirp_themes.dart';

export 'chirp_style.dart';
export 'chirp_themes.dart';

/// A fonte do Chirp, empacotada (assets/fonts, SIL OFL). Os alfabetos que ela não
/// tem (o cirílico, o chinês) caem na fonte do sistema.
const chirpFont = 'Urbanist';

/// O verde de quem está ao alcance, no claro e no escuro.
const _reachableLight = Color(0xFF2E7D32);
const _reachableDark = Color(0xFF7BD77F);

/// O QR fica escuro sobre claro nos dois temas: leitores de QR esperam assim.
const qrDark = Color(0xFF000000);
const qrLight = Color(0xFFFFFFFF);

ColorScheme chirpScheme(ChirpThemeSpec spec, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: spec.seed,
    brightness: brightness,
    dynamicSchemeVariant: spec.variant,
  );
  final tertiary = spec.tertiary;
  if (tertiary == null) return scheme;
  // A terciária vem da semente dela, com os mesmos tons da primária de lá.
  final accent = ColorScheme.fromSeed(
    seedColor: tertiary,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  return scheme.copyWith(
    tertiary: accent.primary,
    onTertiary: accent.onPrimary,
    tertiaryContainer: accent.primaryContainer,
    onTertiaryContainer: accent.onPrimaryContainer,
  );
}

ThemeData chirpTheme(
  Brightness brightness, {
  ChirpThemeSpec? spec,
  bool glass = false,
}) {
  spec ??= chirpThemes.first;
  final scheme = chirpScheme(spec, brightness);
  final corners = BorderRadius.circular(spec.radius);
  final rounded = RoundedRectangleBorder(borderRadius: corners);
  // Com cantos grandes, os botões são pílulas, como no M3; com pequenos, seguem o tema.
  final OutlinedBorder button = spec.radius >= 12
      ? const StadiumBorder()
      : RoundedRectangleBorder(borderRadius: corners);
  final buttonStyle = ButtonStyle(shape: WidgetStatePropertyAll(button));
  final dark = brightness == Brightness.dark;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  // A Urbanist é estreita: os pesos sobem um degrau para ler bem em tamanho pequeno.
  final text = base.textTheme
      .apply(fontFamily: chirpFont)
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w800,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w700,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontFamily: chirpFont,
          fontWeight: FontWeight.w500,
        ),
      );
  final big = BorderRadius.circular(spec.radius + 8);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: chirpFont,
    textTheme: text,
    visualDensity: spec.density,
    extensions: [
      spec.style.copyWith(
        glass: glass,
        reachable: dark ? _reachableDark : _reachableLight,
      ),
    ],
    // Os cartões são superfícies tonais, sem sombra, um pouco mais redondos que
    // os campos (o M3 Expressive).
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: big),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: big),
    ),
    chipTheme: ChipThemeData(shape: rounded),
    // Um retângulo de cantos arredondados, mesmo nos temas mais redondos: a pílula
    // num item de duas linhas fica larga demais.
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.radius.clamp(4, 12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: buttonStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(style: buttonStyle),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.radius.clamp(2, 16)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.radius.clamp(2, 12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: corners),
    ),
  );
}
