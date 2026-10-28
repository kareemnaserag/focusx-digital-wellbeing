import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'onboarding_screen.dart';
import 'strings.dart';
import 'theme.dart';

class FocusXApp extends StatefulWidget {
  const FocusXApp({super.key});

  @override
  State<FocusXApp> createState() => _FocusXAppState();
}

class _FocusXAppState extends State<FocusXApp> {
  Locale _locale = const Locale('ar');
  bool _onboardingComplete = false;

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_locale);
    return MaterialApp(
      title: 'FOCUSX',
      debugShowCheckedModeBanner: false,
      theme: FocusXTheme.dark,
      locale: _locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) => Directionality(
        textDirection: _locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _onboardingComplete
          ? AppShell(
              locale: _locale,
              strings: strings,
              onLocaleChanged: _setLocale,
            )
          : OnboardingScreen(
              strings: strings,
              locale: _locale,
              onLocaleChanged: _setLocale,
              onComplete: () => setState(() => _onboardingComplete = true),
            ),
    );
  }
}
