import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  // ── General ──────────────────────────────────────────────
  String get appTitle;
  String get loading;
  String get close;
  String get back;
  String get start;
  String get description;

  // ── Navigation / Drawer ──────────────────────────────────
  String get zones;
  String get trails;
  String get history;
  String get profile;
  String get settings;
  String get logout;
  String get favorites;
  String get explore;
  String get account_section;
  String get close_menu;

  // ── Auth ─────────────────────────────────────────────────
  String get login;
  String get register;
  String get account;
  String get email_label;
  String get password_label;
  String get confirm_password;
  String get username_label;
  String get fill_all_fields;
  String get login_success;
  String get login_failed;
  String get passwords_no_match;
  String get register_requires_internet;
  String get register_success;
  String get register_failed;
  String get no_connection_login;
  String get session_expired;

  // ── Zones ─────────────────────────────────────────────────
  String get aboutZone;
  String get viewTrails;
  String get unlockZone;
  String get seeMore;
  String get no_zones_available;
  String get select_municipality;
  String get show_all;
  String get no_description;
  String get redirecting_purchase;

  // ── Trails ────────────────────────────────────────────────
  String get no_trails_available;
  String get untitled_trail;
  String get bike_friendly;
  String get no_bikes;

  // ── Trail Map ─────────────────────────────────────────────
  String get start_trail_title;
  String get start_trail_body;

  // ── POIs ──────────────────────────────────────────────────
  String get poi_default_name;
  String get fauna;
  String get flora;
  String get geology;
  String get user_messages;
  String get no_info;
  String get leave_message;

  // ── Profile ───────────────────────────────────────────────
  String get welcome;
  String get completed;
  String get change_language;
  String get change_password;
  String get manage_offline_maps;
  String get trail_history_option;

  // ── Favorites ─────────────────────────────────────────────
  String get favorite_added;
  String get favorite_removed;
  String get favorite_added_offline;
  String get favorite_removed_offline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
