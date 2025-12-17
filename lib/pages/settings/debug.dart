import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:provider/provider.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/pages/settings/cache_debug.dart';
import 'package:waterflyiii/pages/settings/cache_staleness_manual_test.dart';
import 'package:waterflyiii/settings.dart';

class DebugDialog extends StatelessWidget {
  const DebugDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                S.of(context).settingsDialogDebugTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Text(S.of(context).settingsDialogDebugInfo),
                    ),
                    SwitchListTile(
                      value: context.select((SettingsProvider s) => s.debug),
                      onChanged:
                          (bool value) =>
                              context.read<SettingsProvider>().debug = value,

                      title: Text(S.of(context).settingsDialogDebugTitle),
                      secondary: const Icon(Icons.bug_report),
                    ),
                    const Divider(),
                    Builder(
                      builder:
                          (BuildContext context) => SwitchListTile(
                            value: context.select(
                              (SettingsProvider s) => s.enableCaching,
                            ),
                            onChanged: (bool value) async {
                              final BuildContext dialogContext = context;
                              if (!value) {
                                // Show confirmation dialog when disabling cache
                                final bool? confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  builder:
                                      (BuildContext context) => AlertDialog(
                                        icon: const Icon(
                                          Icons.warning_amber_rounded,
                                        ),
                                        title: const Text('Disable Cache?'),
                                        content: const Text(
                                          'Disabling the cache will clear all cached data and '
                                          'may result in slower performance and increased network usage. '
                                          'The app will fetch all data from the server on every request.\n\n'
                                          'Are you sure you want to disable caching?',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(
                                              MaterialLocalizations.of(
                                                context,
                                              ).cancelButtonLabel,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                              foregroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onError,
                                            ),
                                            child: const Text('Disable'),
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                          ),
                                        ],
                                      ),
                                );
                                if (!(confirmed ?? false)) {
                                  return;
                                }
                              }
                              if (!dialogContext.mounted) return;
                              dialogContext
                                  .read<SettingsProvider>()
                                  .enableCaching = value;
                            },
                            title: const Text('Cache-First Architecture'),
                            subtitle: const Text(
                              'Enables local caching for faster performance and reduced '
                              'network usage. Cached data is automatically refreshed when stale.',
                            ),
                            secondary: Icon(
                              context.select(
                                    (SettingsProvider s) => s.enableCaching,
                                  )
                                  ? Icons.cached
                                  : Icons.cloud_download_outlined,
                            ),
                          ),
                    ),
                    ListTile(
                      enabled:
                          context.select((SettingsProvider s) => s.debug) &&
                          context.select(
                            (SettingsProvider s) => s.enableCaching,
                          ),
                      isThreeLine: false,
                      leading: const Icon(Icons.developer_board),
                      title: const Text('Cache Debug UI'),
                      subtitle: const Text(
                        'View cache statistics, entries, and manage cache manually',
                      ),
                      onTap: () {
                        Navigator.of(context).pop(); // Close debug dialog
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) =>
                                    const CacheDebugPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      enabled:
                          context.select((SettingsProvider s) => s.debug) &&
                          context.select(
                            (SettingsProvider s) => s.enableCaching,
                          ),
                      isThreeLine: false,
                      leading: const Icon(Icons.science),
                      title: const Text('Cache Staleness Test'),
                      subtitle: const Text(
                        'Manual test for TTL-based staleness detection',
                      ),
                      onTap: () {
                        Navigator.of(context).pop(); // Close debug dialog
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) =>
                                    const CacheStalenessManualTestPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      enabled: context.select((SettingsProvider s) => s.debug),
                      isThreeLine: false,
                      leading: const Icon(Icons.send),
                      title: Text(S.of(context).settingsDialogDebugSendButton),
                      onTap: () async {
                        final bool? ok = await showDialog<bool>(
                          context: context,
                          builder:
                              (BuildContext context) => AlertDialog(
                                icon: const Icon(Icons.mail),
                                title: Text(
                                  S.of(context).settingsDialogDebugSendButton,
                                ),
                                clipBehavior: Clip.hardEdge,
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                      MaterialLocalizations.of(
                                        context,
                                      ).cancelButtonLabel,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FilledButton(
                                    child: Text(
                                      S
                                          .of(context)
                                          .settingsDialogDebugMailCreate,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                                content: Text(
                                  S
                                      .of(context)
                                      .settingsDialogDebugMailDisclaimer,
                                ),
                              ),
                        );
                        if (!(ok ?? false)) {
                          return;
                        }

                        final PackageInfo appInfo =
                            await PackageInfo.fromPlatform();
                        final Directory tmpPath = await getTemporaryDirectory();
                        final String logPath = "${tmpPath.path}/debuglog.txt";
                        final bool logExists = await File(logPath).exists();
                        await FlutterEmailSender.send(
                          Email(
                            body:
                                "Debug Logs generated from ${appInfo.appName}, ${appInfo.version}+${appInfo.buildNumber}",
                            subject: "Waterfly III Debug Logs",
                            recipients: <String>["app@vogt.pw"],
                            attachmentPaths:
                                logExists
                                    ? <String>[logPath]
                                    : const <String>[],
                            isHTML: false,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
