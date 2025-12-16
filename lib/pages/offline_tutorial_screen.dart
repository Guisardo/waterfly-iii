import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

/// Tutorial screen for offline mode features.
///
/// Features:
/// - Show on first offline mode activation
/// - Explain offline capabilities
/// - Explain sync process
/// - Explain conflict resolution
/// - "Don't Show Again" option
/// - Material 3 design with page indicators
class OfflineTutorialScreen extends StatefulWidget {
  const OfflineTutorialScreen({super.key});

  @override
  State<OfflineTutorialScreen> createState() => _OfflineTutorialScreenState();
}

class _OfflineTutorialScreenState extends State<OfflineTutorialScreen> {
  static final Logger _logger = Logger('OfflineTutorialScreen');
  static const String _tutorialShownKey = 'offline_tutorial_shown';

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final List<_TutorialPage> _pages = <_TutorialPage>[
    _TutorialPage(
      icon: Icons.cloud_off,
      title: 'Work Offline',
      description: 'Continue using Waterfly III even without an internet connection. '
          'All your changes are saved locally and will sync automatically when you\'re back online.',
    ),
    _TutorialPage(
      icon: Icons.sync,
      title: 'Automatic Sync',
      description: 'Your offline changes are queued and synced automatically when you reconnect. '
          'You can also manually trigger a sync anytime from the sync status screen.',
    ),
    _TutorialPage(
      icon: Icons.warning_amber,
      title: 'Conflict Resolution',
      description: 'If the same data is modified both locally and on the server, you\'ll be notified '
          'and can choose how to resolve the conflict.',
    ),
    _TutorialPage(
      icon: Icons.check_circle,
      title: 'You\'re All Set!',
      description: 'Offline mode is now enabled. Look for the cloud icon in the app bar to see your sync status.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (int index) => _buildPageIndicator(index),
              ),
            ),
            const SizedBox(height: 24),

            // Don't show again checkbox
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (bool? value) {
                setState(() {
                  _dontShowAgain = value ?? false;
                });
              },
              title: const Text('Don\'t show this again'),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  FilledButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _finish
                        : _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            page.icon,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    if (_dontShowAgain) {
      await _saveTutorialShown();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveTutorialShown() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialShownKey, true);
      _logger.info('Tutorial marked as shown');
    } catch (e, stackTrace) {
      _logger.warning('Failed to save tutorial shown state', e, stackTrace);
    }
  }

  /// Check if tutorial should be shown
  // ignore: unused_element
  static Future<bool> shouldShow() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_tutorialShownKey) ?? false);
    } catch (e) {
      return true;
    }
  }
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;

  _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
