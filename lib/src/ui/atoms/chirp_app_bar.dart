// lib/src/ui/atoms/chirp_app_bar.dart
//
// A barra de cima das telas que rolam por baixo dela (a lista e a conversa). Com o
// vidro, ela fica translúcida e borra o que passa embaixo; a tela pede o
// `extendBodyBehindAppBar` pelo [ChirpAppBar.extendsBody] e soma o [topInset] no
// começo da lista. Sem vidro, é a AppBar de sempre.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/chirp_style.dart';

class ChirpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChirpAppBar({
    super.key,
    required this.title,
    this.actions,
    this.titleSpacing,
  });

  final Widget title;
  final List<Widget>? actions;
  final double? titleSpacing;

  /// O corpo passa por baixo da barra (só com o vidro valendo).
  static bool extendsBody(BuildContext context) => ChirpStyle.glassOn(context);

  /// Quanto a lista desce para começar abaixo da barra, quando passa por baixo dela:
  /// a barra e o que o sistema ocupa em cima. Lido do contexto da tela (fora do
  /// Scaffold, onde o padding ainda não conta a barra).
  static double topInset(BuildContext context) => extendsBody(context)
      ? MediaQuery.paddingOf(context).top + kToolbarHeight
      : 0;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!ChirpStyle.glassOn(context)) {
      return AppBar(title: title, actions: actions, titleSpacing: titleSpacing);
    }
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: title,
      actions: actions,
      titleSpacing: titleSpacing,
      // Translúcida o bastante para borrar, opaca o bastante para o título ler.
      backgroundColor: scheme.surface.withValues(alpha: 0.78),
      scrolledUnderElevation: 0,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
