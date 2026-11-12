// lib/src/ui/atoms/cockatiel.dart
//
// A calopsita do Chirp: o rosto da calopsita cinza dos jogos do Psito (a ave 6 do
// Psito Nest, CC0), recortado num círculo. Aparece nos estados vazios e na marca.
// Decorativa: o texto ao lado diz o que importa.
import 'package:material_ui/material_ui.dart';

class Cockatiel extends StatelessWidget {
  const Cockatiel({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipOval(
      child: Image.asset(
        'assets/images/cockatiel.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    ),
  );
}
