import 'package:chirp/models/tiel.dart';
import 'package:flutter/material.dart';

class FlockListItem extends StatelessWidget {
  final Tiel tiel;

  String get avatarUrl =>
      "https://api.dicebear.com/7.x/adventurer/png?seed=${tiel.name}";

  String get statusText => switch (tiel.status) {
    TielStatus.searching => "Procurando bando...",
    TielStatus.connected => "Voando em grupo",
    TielStatus.disconnected => "Asas paradas",
    TielStatus.error => "Opa, algo deu errado!",
  };

  const FlockListItem({super.key, required this.tiel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Avatar com borda sutil
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                backgroundImage: NetworkImage(avatarUrl),
              ),

              if (tiel.status == TielStatus.connected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tiel.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
