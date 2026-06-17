// lib/core/l10n/app_localizations.dart
// VERTX — Bilingual strings: Swahili (sw) + English (en)
// Kenya-first: Swahili is default, English fallback

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('sw'), // Swahili
    Locale('en'), // English
  ];

  bool get isSw => locale.languageCode == 'sw';

  // ── Auth ──────────────────────────────────────────────────
  String get signIn => isSw ? 'Ingia' : 'Sign In';
  String get signUp => isSw ? 'Jisajili' : 'Sign Up';
  String get signOut => isSw ? 'Toka' : 'Sign Out';
  String get email => isSw ? 'Barua Pepe' : 'Email';
  String get password => isSw ? 'Nywila' : 'Password';
  String get fullName => isSw ? 'Jina Kamili' : 'Full Name';
  String get confirmPassword => isSw ? 'Thibitisha Nywila' : 'Confirm Password';
  String get noAccount => isSw ? 'Huna akaunti?' : "Don't have an account?";
  String get hasAccount => isSw ? 'Una akaunti?' : 'Already have an account?';
  String get loginFailed =>
      isSw ? 'Nywila au barua pepe si sahihi.' : 'Invalid email or password.';

  // ── Navigation ────────────────────────────────────────────
  String get navHome => isSw ? 'Nyumbani' : 'Home';
  String get navSearch => isSw ? 'Tafuta' : 'Search';
  String get navWatching => isSw ? 'Endelea' : 'Watching';
  String get navProfile => isSw ? 'Wasifu' : 'Profile';

  // ── Content ───────────────────────────────────────────────
  String get episodes => isSw ? 'Vipindi' : 'Episodes';
  String get episode => isSw ? 'Kipindi' : 'Episode';
  String get watchNow => isSw ? 'Tazama Sasa' : 'Watch Now';
  String get continueWatch => isSw ? 'Endelea Kutazama' : 'Continue Watching';
  String get newSeries => isSw ? 'Mipangilio Mipya' : 'New Series';
  String get featured => isSw ? 'Iliyoangaziwa' : 'Featured';
  String get trending => isSw ? 'Inayoendelea' : 'Trending';
  String get free => isSw ? 'Bila Malipo' : 'Free';
  String get moreDetails => isSw ? 'Maelezo Zaidi' : 'More Details';

  // ── Genres ────────────────────────────────────────────────
  String get drama => isSw ? 'Mchezo wa Kuigiza' : 'Drama';
  String get thriller => isSw ? 'Msisimko' : 'Thriller';
  String get romance => isSw ? 'Mapenzi' : 'Romance';
  String get comedy => isSw ? 'Vichekesho' : 'Comedy';
  String get action => isSw ? 'Vitendo' : 'Action';

  // ── Paywall ───────────────────────────────────────────────
  String get unlockContent => isSw ? 'Fungua Maudhui' : 'Unlock Content';
  String get subscribeNow => isSw ? 'Jiandikishe Sasa' : 'Subscribe Now';
  String get weeklyPlan => isSw ? 'Wiki moja' : 'Weekly';
  String get monthlyPlan => isSw ? 'Mwezi mmoja' : 'Monthly';
  String get payWithMpesa => isSw ? 'Lipa na M-Pesa' : 'Pay with M-Pesa';
  String get enterPhone => isSw ? 'Weka Nambari ya Simu' : 'Enter Phone Number';
  String get mpesaPrompt => isSw
      ? 'Ombi la M-Pesa limetumwa. Ingiza PIN yako.'
      : 'M-Pesa prompt sent. Enter your PIN.';
  String get paymentSuccess =>
      isSw ? 'Malipo yamekamilika!' : 'Payment successful!';
  String get paymentFailed =>
      isSw ? 'Malipo hayakufanikiwa.' : 'Payment failed.';
  String get alreadyOwns =>
      isSw ? 'Tayari unamiliki maudhui haya.' : 'You already own this content.';
  String get orBuyOnce =>
      isSw ? 'Au nunua mfululizo huu mara moja' : 'Or buy this series once';

  // ── Player ────────────────────────────────────────────────
  String get swipeNext => isSw
      ? 'Sogeza Juu kwa Kipindi Kinachofuata'
      : 'Swipe up for next episode';
  String get swipePrev => isSw
      ? 'Sogeza Chini kwa Kipindi Kilichopita'
      : 'Swipe down for previous episode';
  String get episodeComplete =>
      isSw ? 'Kipindi kimekamilika' : 'Episode complete';
  String get nextEpisode => isSw ? 'Kipindi Kinachofuata' : 'Next Episode';

  // ── General ───────────────────────────────────────────────
  String get loading => isSw ? 'Inapakia...' : 'Loading...';
  String get retry => isSw ? 'Jaribu Tena' : 'Try Again';
  String get cancel => isSw ? 'Ghairi' : 'Cancel';
  String get confirm => isSw ? 'Thibitisha' : 'Confirm';
  String get error => isSw ? 'Hitilafu' : 'Error';
  String get noContent => isSw ? 'Hakuna maudhui bado.' : 'No content yet.';
  String get searchHint => isSw ? 'Tafuta vipindi...' : 'Search series...';

  // ── Phone validation ──────────────────────────────────────
  String get phoneHint => isSw ? 'mf. 0712345678' : 'e.g. 0712345678';
  String get phoneInvalid =>
      isSw ? 'Weka nambari sahihi ya Kenya' : 'Enter a valid Kenyan number';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['sw', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
