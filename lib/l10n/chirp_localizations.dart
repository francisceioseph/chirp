import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'chirp_localizations_de.dart';
import 'chirp_localizations_en.dart';
import 'chirp_localizations_es.dart';
import 'chirp_localizations_fr.dart';
import 'chirp_localizations_pt.dart';
import 'chirp_localizations_ru.dart';
import 'chirp_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ChirpLocalizations
/// returned by `ChirpLocalizations.of(context)`.
///
/// Applications need to include `ChirpLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/chirp_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ChirpLocalizations.localizationsDelegates,
///   supportedLocales: ChirpLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ChirpLocalizations.supportedLocales
/// property.
abstract class ChirpLocalizations {
  ChirpLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ChirpLocalizations of(BuildContext context) {
    return Localizations.of<ChirpLocalizations>(context, ChirpLocalizations)!;
  }

  static const LocalizationsDelegate<ChirpLocalizations> delegate =
      _ChirpLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The app name, in the window title and the about box.
  ///
  /// In en, this message translates to:
  /// **'Psito Chirp'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations that stay between you'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'No accounts, no servers, no logs. Your messages live only on your devices.'**
  String get welcomeBody;

  /// No description provided for @coreVersion.
  ///
  /// In en, this message translates to:
  /// **'Core {version} · protocol {protocol}'**
  String coreVersion(String version, int protocol);

  /// No description provided for @coreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The secure core could not start.'**
  String get coreUnavailable;

  /// No description provided for @foundationNote.
  ///
  /// In en, this message translates to:
  /// **'This is the foundation of the new Chirp. Conversations arrive in the next phases.'**
  String get foundationNote;
}

class _ChirpLocalizationsDelegate
    extends LocalizationsDelegate<ChirpLocalizations> {
  const _ChirpLocalizationsDelegate();

  @override
  Future<ChirpLocalizations> load(Locale locale) {
    return SynchronousFuture<ChirpLocalizations>(
      lookupChirpLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_ChirpLocalizationsDelegate old) => false;
}

ChirpLocalizations lookupChirpLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return ChirpLocalizationsDe();
    case 'en':
      return ChirpLocalizationsEn();
    case 'es':
      return ChirpLocalizationsEs();
    case 'fr':
      return ChirpLocalizationsFr();
    case 'pt':
      return ChirpLocalizationsPt();
    case 'ru':
      return ChirpLocalizationsRu();
    case 'zh':
      return ChirpLocalizationsZh();
  }

  throw FlutterError(
    'ChirpLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
