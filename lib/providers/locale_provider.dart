import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_locale';
  String _locale = 'fr';

  String get locale => _locale;
  bool get isFrench => _locale == 'fr';
  bool get isPulaar => _locale == 'ff';

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_key) ?? 'fr';
    AppLocalizations.setLocale(_locale);
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    AppLocalizations.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await setLocale(_locale == 'fr' ? 'ff' : 'fr');
  }

  String tr(String key) => AppLocalizations.get(key);
}
