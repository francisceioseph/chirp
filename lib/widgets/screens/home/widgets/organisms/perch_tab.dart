import 'package:chirp/app/controllers/chirp_controller.dart';
import 'package:chirp/widgets/atoms/chirp_brand_identity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PerchTab extends StatelessWidget {
  const PerchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChirpController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  gradient: SweepGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0),
                      colorScheme.primary.withValues(alpha: 0.5),
                      colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: colorScheme.surface,
                  backgroundImage: NetworkImage(
                    "https://api.dicebear.com/7.x/adventurer/png?seed=${controller.myName}",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            controller.myName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              controller.myId,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.primary.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 40),
          const Divider(thickness: 0.5, indent: 50, endIndent: 50),
          const SizedBox(height: 40),

          const Center(
            child: ChirpBrandIdentity(alignment: CrossAxisAlignment.center),
          ),

          const SizedBox(height: 56),

          // Botão com Glassmorphism sutil
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            icon: const Icon(Icons.qr_code_2),
            label: const Text("Meu QR Chirp"),
          ),
        ],
      ),
    );
  }
}
