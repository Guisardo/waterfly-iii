import 'package:flutter/material.dart';

/// Help screen explaining offline mode features.
///
/// Features:
/// - How offline mode works
/// - Understanding sync status
/// - Resolving conflicts
/// - FAQ section
/// - Troubleshooting guide
class OfflineHelpScreen extends StatelessWidget {
  const OfflineHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'How Offline Mode Works',
            Icons.cloud_off,
            [
              'Offline mode allows you to use Waterfly III without an internet connection.',
              'All changes are saved locally on your device.',
              'When you reconnect, changes are automatically synced with the server.',
              'You can view and edit transactions, accounts, categories, and more.',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Understanding Sync Status',
            Icons.sync,
            [
              'Green cloud icon: All data is synced',
              'Yellow cloud icon: Pending operations waiting to sync',
              'Red cloud icon: You are offline',
              'Blue syncing icon: Sync in progress',
              'Tap the icon to view detailed sync status',
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Resolving Conflicts',
            Icons.warning_amber,
            [
              'Conflicts occur when the same data is modified both locally and on the server.',
              'You\'ll be notified when conflicts are detected.',
              'Choose to keep local changes, use server version, or merge both.',
              'Low severity conflicts can be auto-resolved.',
              'High severity conflicts require manual resolution.',
            ],
          ),
          const SizedBox(height: 24),
          _buildFAQSection(context),
          const SizedBox(height: 24),
          _buildTroubleshootingSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> points,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                      Expanded(
                        child: Text(
                          point,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'Will my data be safe offline?',
        'answer': 'Yes, all data is stored securely on your device and synced when online.',
      },
      {
        'question': 'What happens if I delete something offline?',
        'answer': 'The deletion will be synced when you reconnect. If the item was modified on the server, you\'ll be notified of a conflict.',
      },
      {
        'question': 'Can I use offline mode on multiple devices?',
        'answer': 'Yes, but be aware that changes on different devices may create conflicts that need to be resolved.',
      },
      {
        'question': 'How long can I stay offline?',
        'answer': 'There\'s no time limit. You can work offline as long as needed.',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Frequently Asked Questions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...faqs.map((faq) => ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        faq['answer']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection(BuildContext context) {
    final issues = [
      {
        'problem': 'Sync is not working',
        'solution': 'Check your internet connection. Try manually syncing from the sync status screen. If the problem persists, try force full sync in settings.',
      },
      {
        'problem': 'Too many conflicts',
        'solution': 'Avoid making changes on multiple devices while offline. Sync frequently when online to minimize conflicts.',
      },
      {
        'problem': 'Data seems outdated',
        'solution': 'Pull down to refresh on list screens. Check the last sync time in the dashboard sync status card.',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Troubleshooting',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue['problem']!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue['solution']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
