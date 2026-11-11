// lib/src/ui/time_format.dart
//
// A hora de uma mensagem: só a hora quando é de hoje, e o dia junto quando não é. No
// formato do idioma do app.
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String messageTime(BuildContext context, DateTime time, {DateTime? now}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final today = now ?? DateTime.now();
  final sameDay =
      time.year == today.year &&
      time.month == today.month &&
      time.day == today.day;
  return sameDay
      ? DateFormat.Hm(locale).format(time)
      : DateFormat.MMMd(locale).add_Hm().format(time);
}
