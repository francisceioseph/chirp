import 'package:chirp/controllers/chirp_controller.dart';
import 'package:chirp/widgets/components/app_header.dart';
import 'package:chirp/widgets/components/flock_list.dart';
import 'package:chirp/widgets/components/glass_panel.dart';
import 'package:chirp/widgets/screens/home/widgets/liquid_orb.dart';
import 'package:chirp/widgets/screens/home/widgets/column_label.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    final chirpCtrl = context.watch<ChirpController>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: LiquidOrb(
              color: isDark
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.onSurface.withValues(alpha: 0.3),
              size: 400,
            ),
          ),

          Positioned(
            bottom: -150,
            left: 200,
            child: LiquidOrb(
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
              child: LiquidOrb(
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
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: GlassPanel(
                            child: ListenableBuilder(
                              listenable: chirpCtrl,
                              builder: (context, _) {
                                final tiels = chirpCtrl.nearbyTiels;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const ColumnLabel(label: "Bando"),

                                    Expanded(child: FlockList(tiels: tiels)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 8,
                          child: GlassPanel(
                            child: ColumnLabel(label: "Mensagens"),
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
