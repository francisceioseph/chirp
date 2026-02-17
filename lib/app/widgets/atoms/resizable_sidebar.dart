import 'package:flutter/material.dart';

class ResizableSidebar extends StatefulWidget {
  final Widget child;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;

  const ResizableSidebar({
    super.key,
    required this.child,
    this.initialWidth = 300,
    this.minWidth = 300,
    this.maxWidth = 500,
  });

  @override
  State<ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<ResizableSidebar> {
  late double _width;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _width, child: widget.child),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _width += details.delta.dx;
              _width = _width.clamp(widget.minWidth, widget.maxWidth);
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: Container(width: 4, color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
