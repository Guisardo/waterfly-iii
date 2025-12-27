import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_ca.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_cs.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_da.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_de.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_en.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_es.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_fa.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_fr.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_hu.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_id.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_it.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_ko.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_nl.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_pl.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_pt.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_ro.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_ru.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_sl.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_sv.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_tr.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_uk.dart';
import 'package:waterflyiii/generated/l10n/app_localizations_zh.dart';
import 'package:waterflyiii/settings.dart';

final Logger log = Logger("SyncNotifications");

class SyncNotifications {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  SettingsProvider? _settingsProvider;
  
  void setSettingsProvider(SettingsProvider? provider) {
    _settingsProvider = provider;
  }
  
  // Get localized string based on current locale
  String _getLocalizedString(String Function(S) getter) {
    final Locale? locale = _settingsProvider?.locale;
    if (locale == null) {
      return getter(SEn('en'));
    }
    
    // Map locale to appropriate S class
    final String langCode = locale.languageCode.toLowerCase();
    switch (langCode) {
      case 'ca':
        return getter(SCa('ca'));
      case 'cs':
        return getter(SCs('cs'));
      case 'da':
        return getter(SDa('da'));
      case 'de':
        return getter(SDe('de'));
      case 'es':
        return getter(SEs('es'));
      case 'fa':
        return getter(SFa('fa'));
      case 'fr':
        return getter(SFr('fr'));
      case 'hu':
        return getter(SHu('hu'));
      case 'id':
        return getter(SId('id'));
      case 'it':
        return getter(SIt('it'));
      case 'ko':
        return getter(SKo('ko'));
      case 'nl':
        return getter(SNl('nl'));
      case 'pl':
        return getter(SPl('pl'));
      case 'pt':
        if (locale.countryCode?.toLowerCase() == 'br') {
          return getter(SPtBr());
        }
        return getter(SPt('pt'));
      case 'ro':
        return getter(SRo('ro'));
      case 'ru':
        return getter(SRu('ru'));
      case 'sl':
        return getter(SSl('sl'));
      case 'sv':
        return getter(SSv('sv'));
      case 'tr':
        return getter(STr('tr'));
      case 'uk':
        return getter(SUk('uk'));
      case 'zh':
        if (locale.countryCode?.toLowerCase() == 'tw') {
          return getter(SZhTw());
        }
        return getter(SZh('zh'));
      default:
        return getter(SEn('en'));
    }
  }

  static const int syncNotificationId = 1000;
  static const int credentialErrorNotificationId = 1001;
  static const int syncPausedNotificationId = 1002;

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
  }

  Future<void> showSyncStarted() async {
    final String channelName = _getLocalizedString((l) => l.syncNotificationChannelName);
    final String channelDesc = _getLocalizedString((l) => l.syncNotificationChannelDescription);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sync',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      indeterminate: true,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final String title = _getLocalizedString((l) => l.syncNotificationSyncing);
    final String body = _getLocalizedString((l) => l.syncNotificationSyncingBody);
    
    await _notifications.show(
      syncNotificationId,
      title,
      body,
      details,
    );
  }

  Future<void> showSyncProgress({
    required String entityType,
    required int current,
    required int total,
    String? message,
  }) async {
    final String channelName = _getLocalizedString((l) => l.syncNotificationChannelName);
    final String channelDesc = _getLocalizedString((l) => l.syncNotificationChannelDescription);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sync',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: total,
      progress: current,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final String title = _getLocalizedString((l) => l.syncNotificationSyncingEntity(entityType));
    
    await _notifications.show(
      syncNotificationId,
      title,
      message ?? '$current / $total',
      details,
    );
  }

  Future<void> showSyncCompleted() async {
    await _notifications.cancel(syncNotificationId);

    final String channelName = _getLocalizedString((l) => l.syncNotificationChannelName);
    final String channelDesc = _getLocalizedString((l) => l.syncNotificationChannelDescription);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sync',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.low,
      priority: Priority.low,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final String title = _getLocalizedString((l) => l.syncNotificationCompleted);
    final String body = _getLocalizedString((l) => l.syncNotificationCompletedBody);
    
    await _notifications.show(
      syncNotificationId,
      title,
      body,
      details,
    );
  }

  Future<void> showSyncPaused(String error) async {
    await _notifications.cancel(syncNotificationId);

    final String channelName = _getLocalizedString((l) => l.syncNotificationChannelName);
    final String channelDesc = _getLocalizedString((l) => l.syncNotificationChannelDescription);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sync',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final String title = _getLocalizedString((l) => l.syncNotificationPaused);
    final String body = _getLocalizedString((l) => l.syncNotificationPausedBody);
    
    await _notifications.show(
      syncPausedNotificationId,
      title,
      body,
      details,
    );
  }

  Future<void> showCredentialError() async {
    await _notifications.cancel(syncNotificationId);

    final String channelName = _getLocalizedString((l) => l.syncNotificationChannelName);
    final String channelDesc = _getLocalizedString((l) => l.syncNotificationChannelDescription);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sync',
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    final String title = _getLocalizedString((l) => l.syncNotificationAuthError);
    final String body = _getLocalizedString((l) => l.syncNotificationAuthErrorBody);
    
    await _notifications.show(
      credentialErrorNotificationId,
      title,
      body,
      details,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

