import 'package:chirp/models/tiel.dart';
import 'package:chirp/widgets/components/flock_list_item.dart';
import 'package:flutter/material.dart';

class FlockList extends StatelessWidget {
  final List<Tiel> tiels;

  const FlockList({super.key, required this.tiels});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tiels.length,
      itemBuilder: (context, index) {
        return FlockListItem(tiel: tiels[index]);
      },
    );
  }
}
