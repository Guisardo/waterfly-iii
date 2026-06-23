import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:logging/logging.dart';

import 'package:timezone/data/latest.dart' as tz;

import 'package:waterflyiii/app.dart';
import 'package:waterflyiii/services/sync/sync_log_sanitizer.dart';

void main() async {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((LogRecord record) {
    final String message = sanitizeSyncLogText(record.message);
    final Object? error = record.error == null
        ? null
        : sanitizeSyncLogText(record.error);
    final StackTrace? stackTrace = record.stackTrace == null
        ? null
        : StackTrace.fromString(sanitizeSyncLogText(record.stackTrace));
    developer.log(
      message,
      time: record.time,
      sequenceNumber: record.sequenceNumber,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: error,
      stackTrace: stackTrace,
    );
  });
  tz.initializeTimeZones();
  Intl.defaultLocale = await findSystemLocale();
  await initializeDateFormatting();
  return runApp(const WaterflyApp());
}
