import 'package:chirp/app/themes/cockatiel_glass/sunny_lutino_glass_theme.dart';
import 'package:chirp/app/themes/cockatiel_glass/wild_grey_glass_theme.dart';
import 'package:chirp/app/themes/foundation_slate/foundation_day_slate_themee.dart';
import 'package:chirp/app/themes/foundation_slate/foundation_night_slate_theme.dart';
import 'package:chirp/app/themes/human_slate/human_day_slate_theme.dart';
import 'package:chirp/app/themes/human_slate/human_night_slate_theme.dart';
import 'package:chirp/app/themes/mighty_cats/mighty_cats_day_slate_theme.dart';
import 'package:chirp/app/themes/mighty_cats/mighty_cats_night_slate_theme.dart';
import 'package:chirp/app/themes/old_days_slate/old_days_slate_theme.dart';
import 'package:chirp/app/themes/old_days_slate/old_nights_slate_theme.dart';
import 'package:chirp/app/themes/skylight_themes/skylight_slate_theme.dart';
import 'package:chirp/app/themes/skylight_themes/skynight_slate_theme.dart';
import 'package:chirp/app/themes/symbian_themes/symbian_day_slate_theme.dart';
import 'package:chirp/app/themes/symbian_themes/symbian_night_theme.dart';
import 'package:chirp/domain/entities/chirp_theme.dart';

class ChirpThemeCatalog {
  static final List<ChirpTheme> all = [
    ChirpTheme(
      id: "sunny_lutino",
      name: "Sunny Lutino",
      description: "Inspirado no calor das bochechas laranjas.",
      family: ChirpThemeFamily.lutino,
      light: SunnyLutinoGlassTheme.theme,
      dark: WildGreyGlassTheme.theme,
    ),
    ChirpTheme(
      id: "skylight",
      name: "Chirp Skylight",
      description: "A nostalgia do azul que conectou o mundo.",
      family: ChirpThemeFamily.skylight,
      light: SkylightSlateTheme.theme,
      dark: SkyNightSlateTheme.theme,
    ),
    ChirpTheme(
      id: "old_days",
      name: "Chirp Old Days",
      description: "Cinza industrial e a glória dos 32-bits.",
      family: ChirpThemeFamily.oldDays,
      light: OldDaysSlateTheme.theme,
      dark: OldNightsSlateTheme.theme,
    ),
    ChirpTheme(
      id: "human",
      name: "Chirp Human",
      description: "Ubuntu e a filosofia de conexão humana.",
      family: ChirpThemeFamily.human,
      light: HumanDaySlateTheme.theme,
      dark: HumanNightSlateTheme.theme,
    ),
    ChirpTheme(
      id: "symbian",
      name: "Chirp Symbian",
      description: "O espírito inquebrável da era de ouro mobile.",
      family: ChirpThemeFamily.symbian,
      light: SymbianDaySlateTheme.theme,
      dark: SymbianNightSlateTheme.theme,
    ),
    ChirpTheme(
      id: "foundation",
      name: "Chirp Foundation",
      description: "Minimalismo industrial para foco máximo.",
      family: ChirpThemeFamily.foundation,
      light: FoundationDaySlateTheme.theme,
      dark: FoundationNightSlateTheme.theme,
    ),
    ChirpTheme(
      id: "mighty_cats",
      name: "Mighty Cats",
      description: "O rugido do skeuomorfismo. Alumínio e vidro clássicos.",
      family: ChirpThemeFamily.mightyCats,
      light: MightyCatsDaySlateTheme.theme,
      dark: MightyCatsNightSlateTheme.theme,
    ),
  ];

  static ChirpTheme get defaultTheme => all[0];

  static ChirpTheme findById(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
