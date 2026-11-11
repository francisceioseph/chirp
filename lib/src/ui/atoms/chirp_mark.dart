// lib/src/ui/atoms/chirp_mark.dart
//
// A marca do Chirp num círculo, nas cores do tema. Decorativa: o nome do app vem do
// texto ao lado, então ela fica fora do leitor de tela.
import 'package:flutter/material.dart';

class ChirpMark extends StatelessWidget {
  const ChirpMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.forum_rounded,
          size: size * 0.5,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
