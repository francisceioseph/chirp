import 'package:flutter/widgets.dart';

import 'chirp_localizations.dart';

export 'chirp_localizations.dart';

extension ChirpL10n on BuildContext {
  ChirpLocalizations get l10n => ChirpLocalizations.of(this);
}
