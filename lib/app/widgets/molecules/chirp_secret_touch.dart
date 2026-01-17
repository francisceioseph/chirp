import 'package:flutter/material.dart';

class ChirpSecretTouch extends StatefulWidget {
  final Widget child;
  final VoidCallback onReveal;

  const ChirpSecretTouch({
    super.key,
    required this.child,
    required this.onReveal,
  });

  @override
  State<ChirpSecretTouch> createState() => _ChirpSecretTouchState();
}

class _ChirpSecretTouchState extends State<ChirpSecretTouch> {
  int _counter = 0;
  DateTime? _lastClick;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastClick != null &&
        now.difference(_lastClick!) > const Duration(seconds: 2)) {
      _counter = 0;
    }
    _lastClick = now;
    _counter++;

    if (_counter == 7) {
      _counter = 0;
      widget.onReveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
