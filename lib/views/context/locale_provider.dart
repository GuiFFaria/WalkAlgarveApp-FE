import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('pt');

  Locale get locale => _locale;

  void toggleLocale() {
    _locale = _locale.languageCode == 'pt'
        ? const Locale('en')
        : const Locale('pt');
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
