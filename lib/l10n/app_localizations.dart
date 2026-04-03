import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Walk Algarve'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @zones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get zones;

  /// No description provided for @trails.
  ///
  /// In en, this message translates to:
  /// **'Trails'**
  String get trails;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @account_section.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_section;

  /// No description provided for @close_menu.
  ///
  /// In en, this message translates to:
  /// **'Close menu'**
  String get close_menu;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get account;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_label;

  /// No description provided for @password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_label;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get fill_all_fields;

  /// No description provided for @login_success.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get login_success;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get login_failed;

  /// No description provided for @passwords_no_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwords_no_match;

  /// No description provided for @register_requires_internet.
  ///
  /// In en, this message translates to:
  /// **'You must be connected to the internet to register.'**
  String get register_requires_internet;

  /// No description provided for @register_success.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please login.'**
  String get register_success;

  /// No description provided for @register_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get register_failed;

  /// No description provided for @no_connection_login.
  ///
  /// In en, this message translates to:
  /// **'No connection — please log in online first.'**
  String get no_connection_login;

  /// No description provided for @session_expired.
  ///
  /// In en, this message translates to:
  /// **'Session expired — please log in again.'**
  String get session_expired;

  /// No description provided for @aboutZone.
  ///
  /// In en, this message translates to:
  /// **'About this zone'**
  String get aboutZone;

  /// No description provided for @viewTrails.
  ///
  /// In en, this message translates to:
  /// **'View Trails'**
  String get viewTrails;

  /// No description provided for @unlockZone.
  ///
  /// In en, this message translates to:
  /// **'Buy Zone'**
  String get unlockZone;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @no_zones_available.
  ///
  /// In en, this message translates to:
  /// **'No zones available.'**
  String get no_zones_available;

  /// No description provided for @select_municipality.
  ///
  /// In en, this message translates to:
  /// **'Select Municipality'**
  String get select_municipality;

  /// No description provided for @show_all.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get show_all;

  /// No description provided for @no_description.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get no_description;

  /// No description provided for @redirecting_purchase.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to purchase...'**
  String get redirecting_purchase;

  /// No description provided for @no_trails_available.
  ///
  /// In en, this message translates to:
  /// **'No trails available.'**
  String get no_trails_available;

  /// No description provided for @untitled_trail.
  ///
  /// In en, this message translates to:
  /// **'Untitled Trail'**
  String get untitled_trail;

  /// No description provided for @bike_friendly.
  ///
  /// In en, this message translates to:
  /// **'Bike Friendly'**
  String get bike_friendly;

  /// No description provided for @no_bikes.
  ///
  /// In en, this message translates to:
  /// **'No Bikes'**
  String get no_bikes;

  /// No description provided for @start_trail_title.
  ///
  /// In en, this message translates to:
  /// **'Start trail?'**
  String get start_trail_title;

  /// No description provided for @start_trail_body.
  ///
  /// In en, this message translates to:
  /// **'Do you want to start the trail now?'**
  String get start_trail_body;

  /// No description provided for @poi_default_name.
  ///
  /// In en, this message translates to:
  /// **'Point of Interest'**
  String get poi_default_name;

  /// No description provided for @fauna.
  ///
  /// In en, this message translates to:
  /// **'Fauna'**
  String get fauna;

  /// No description provided for @flora.
  ///
  /// In en, this message translates to:
  /// **'Flora'**
  String get flora;

  /// No description provided for @geology.
  ///
  /// In en, this message translates to:
  /// **'Geology'**
  String get geology;

  /// No description provided for @user_messages.
  ///
  /// In en, this message translates to:
  /// **'User messages'**
  String get user_messages;

  /// No description provided for @no_info.
  ///
  /// In en, this message translates to:
  /// **'No information available.'**
  String get no_info;

  /// No description provided for @leave_message.
  ///
  /// In en, this message translates to:
  /// **'Leave a message'**
  String get leave_message;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Algarve'**
  String get welcome;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get change_language;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get change_password;

  /// No description provided for @manage_offline_maps.
  ///
  /// In en, this message translates to:
  /// **'Manage offline maps'**
  String get manage_offline_maps;

  /// No description provided for @trail_history_option.
  ///
  /// In en, this message translates to:
  /// **'Trail history'**
  String get trail_history_option;

  /// No description provided for @favorite_added.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favorite_added;

  /// No description provided for @favorite_removed.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favorite_removed;

  /// No description provided for @favorite_added_offline.
  ///
  /// In en, this message translates to:
  /// **'Saved as favorite (offline)'**
  String get favorite_added_offline;

  /// No description provided for @favorite_removed_offline.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites (offline)'**
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
  // Lookup logic when only language code is specified.
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
