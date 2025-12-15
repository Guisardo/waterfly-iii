import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/settings.dart';

/// Helper for accessing localized strings without BuildContext.
class LocalizationHelper {
  static S? _cachedLocalizations;
  static Locale? _cachedLocale;

  /// Get localized strings for the user's preferred locale.
  static Future<S> getLocalizations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeStr = prefs.getString(SettingsProvider.settingLocale);
      
      Locale locale;
      if (localeStr != null && localeStr != 'unset') {
        locale = _parseLocale(localeStr);
      } else {
        locale = const Locale('en');
      }

      // Return cached if same locale
      if (_cachedLocale == locale && _cachedLocalizations != null) {
        return _cachedLocalizations!;
      }

      // Load localizations using lookupS
      _cachedLocale = locale;
      _cachedLocalizations = lookupS(locale);
      return _cachedLocalizations!;
    } catch (e) {
      // Fallback to English
      _cachedLocale = const Locale('en');
      _cachedLocalizations = lookupS(const Locale('en'));
      return _cachedLocalizations!;
    }
  }

  static Locale _parseLocale(String localeStr) {
    final parts = localeStr.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  static void clearCache() {
    _cachedLocalizations = null;
    _cachedLocale = null;
  }
}
