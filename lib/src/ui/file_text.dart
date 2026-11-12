// lib/src/ui/file_text.dart
//
// O tamanho de um arquivo no formato do idioma (1,5 MB; 1.5 MB).
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

String fileSize(BuildContext context, int bytes) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toLanguageTag();
  String number(double value) =>
      NumberFormat(value < 10 ? '0.#' : '0', locale).format(value);
  const k = 1024.0;
  if (bytes < k) return l10n.sizeBytes('$bytes');
  if (bytes < k * k) return l10n.sizeKb(number(bytes / k));
  if (bytes < k * k * k) return l10n.sizeMb(number(bytes / (k * k)));
  return l10n.sizeGb(number(bytes / (k * k * k)));
}
