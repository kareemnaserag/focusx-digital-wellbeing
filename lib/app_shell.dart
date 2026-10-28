import 'package:flutter/material.dart';

import 'screens/feature_screens.dart';
import 'screens/home_screen.dart';
import 'strings.dart';
import 'theme.dart';

enum AppPage { home, limits, focus, habits, stats, detox, integration, settings }

class AppShell extends StatefulWidget {
  const AppShell({
    required this.locale,
    required this.strings,
    required this.onLocaleChanged,
    super.key,
  });

  final Locale locale;
  final AppStrings strings;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage _page = AppPage.home;

  static const _bottomPages = [
    AppPage.home,
    AppPage.limits,
    AppPage.focus,
    AppPage.habits,
    AppPage.stats,
  ];

  String _titleFor(AppPage page) => widget.strings.text(switch (page) {
        AppPage.home => 'home',
        AppPage.limits => 'limits',
        AppPage.focus => 'focus',
        AppPage.habits => 'habits',
        AppPage.stats => 'stats',
        AppPage.detox => 'detox',
        AppPage.integration => 'integration',
        AppPage.settings => 'settings',
      });

  void _showPreviewNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.strings.text('feature_preview')),
        content: Text(widget.strings.text('preview_action')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.strings.text('done')),
          ),
        ],
      ),
    );
  }

  Widget _body() => switch (_page) {
        AppPage.home => HomeScreen(
            strings: widget.strings,
            onNavigate: (page) => setState(() => _page = page),
          ),
        AppPage.limits => LimitsScreen(
            strings: widget.strings,
            onOpenIntegration: () =>
                setState(() => _page = AppPage.integration),
          ),
        AppPage.focus => FocusScreen(
            strings: widget.strings,
            onPreviewAction: _showPreviewNotice,
          ),
        AppPage.habits => HabitsScreen(
            strings: widget.strings,
            onPreviewAction: _showPreviewNotice,
          ),
        AppPage.stats => StatsScreen(strings: widget.strings),
        AppPage.detox => DetoxScreen(
            strings: widget.strings,
            onPreviewAction: _showPreviewNotice,
          ),
        AppPage.integration => IntegrationScreen(
            strings: widget.strings,
            onOpenLimits: () => setState(() => _page = AppPage.limits),
          ),
        AppPage.settings => SettingsScreen(
            strings: widget.strings,
            onLocaleChanged: widget.onLocaleChanged,
            onPreviewAction: _showPreviewNotice,
            onOpenIntegration: () =>
                setState(() => _page = AppPage.integration),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _bottomPages.indexOf(_page);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleFor(_page),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: widget.strings.languageLabel,
            onPressed: () => widget.onLocaleChanged(
              Locale(widget.strings.isArabic ? 'en' : 'ar'),
            ),
            icon: const Icon(Icons.translate_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        top: false,
        child: _body(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _page = _bottomPages[index]),
        destinations: [
          _destination(Icons.home_rounded, 'home'),
          _destination(Icons.tune_rounded, 'limits'),
          _destination(Icons.center_focus_strong_rounded, 'focus'),
          _destination(Icons.spa_rounded, 'habits'),
          _destination(Icons.insights_rounded, 'stats'),
        ],
      ),
    );
  }

  NavigationDestination _destination(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(icon, color: FocusXColors.green),
      label: widget.strings.text(label),
    );
  }

  Widget _buildDrawer() {
    final pages = [
      (AppPage.home, Icons.home_rounded, 'home'),
      (AppPage.detox, Icons.do_not_disturb_on_rounded, 'detox'),
      (AppPage.integration, Icons.phonelink_setup_rounded, 'integration'),
      (AppPage.settings, Icons.shield_outlined, 'settings'),
    ];
    final selectedDrawerIndex = pages.indexWhere((item) => item.$1 == _page);
    return NavigationDrawer(
      selectedIndex: selectedDrawerIndex < 0 ? 0 : selectedDrawerIndex,
      onDestinationSelected: (index) {
        Navigator.pop(context);
        setState(() => _page = pages[index].$1);
      },
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(28, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FOCUSX',
                style: TextStyle(
                  color: FocusXColors.green,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.strings.text('brand_tagline'),
                style: const TextStyle(color: FocusXColors.muted),
              ),
            ],
          ),
        ),
        for (final item in pages)
          NavigationDrawerDestination(
            icon: Icon(item.$2),
            label: Text(widget.strings.text(item.$3)),
          ),
      ],
    );
  }
}
