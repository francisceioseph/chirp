import 'package:chirp/widgets/components/app_header.dart';
import 'package:chirp/widgets/components/glass_panel.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _LiquidOrb(
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.onSurface.withValues(alpha: 0.3),
              size: 400,
            ),
          ),

          Positioned(
            bottom: -150,
            left: 200,
            child: _LiquidOrb(
              color: isDark
                  ? colorScheme.secondary.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.3),
              size: 500,
            ),
          ),

          if (!isDark)
            Positioned(
              top: 200,
              left: -100,
              child: _LiquidOrb(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                size: 300,
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          flex: 3,
                          child: GlassPanel(
                            child: _ColumnLabel(icon: "🐦", label: "Bando"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          flex: 7,
                          child: GlassPanel(
                            child: _ColumnLabel(icon: "💬", label: "Mensagens"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _LiquidOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _ColumnLabel extends StatelessWidget {
  final String icon;
  final String label;

  const _ColumnLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              // Uso do onSurface para garantir leitura no Lutino (escuro) e Grey (claro)
              color: colorScheme.onSurface.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
