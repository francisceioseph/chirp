// lib/src/ui/templates/centered_panel.dart
//
// As telas de uma coluna só (abertura, senha, perfil novo, problema): no meio, com
// largura máxima, rolando quando a janela é pequena (até 240×160).
import 'package:flutter/material.dart';

class CenteredPanel extends StatelessWidget {
  const CenteredPanel({
    super.key,
    required this.children,
    this.appBar,
    this.maxWidth = 440,
  });

  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
