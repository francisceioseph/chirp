// lib/src/ui/atoms/chirp_mark.dart
//
// A marca do Chirp: a calopsita, nas cores do tema. Decorativa: o nome do app vem do
// texto ao lado, então ela fica fora do leitor de tela.
import 'package:material_ui/material_ui.dart';

import 'cockatiel.dart';

class ChirpMark extends StatelessWidget {
  const ChirpMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => Cockatiel(size: size);
}
