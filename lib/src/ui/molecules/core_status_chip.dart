// lib/src/ui/molecules/core_status_chip.dart
//
// A versão do núcleo e do protocolo, ou o aviso de que o núcleo não abriu.
import 'package:material_ui/material_ui.dart';

import '../../../l10n/l10n.dart';
import '../../core/chirp_core.dart';

class CoreStatusChip extends StatelessWidget {
  const CoreStatusChip({super.key, required this.info});

  final CoreInfo? info;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final info = this.info;
    if (info == null) {
      return Chip(
        avatar: Icon(Icons.error_outline, color: scheme.error),
        label: Text(l10n.coreUnavailable),
      );
    }
    return Chip(
      avatar: Icon(Icons.verified_user_outlined, color: scheme.primary),
      label: Text(l10n.coreVersion(info.version, info.protocol)),
    );
  }
}
