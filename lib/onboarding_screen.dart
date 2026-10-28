import 'package:flutter/material.dart';

import 'strings.dart';
import 'theme.dart';
import 'widgets/common.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    required this.strings,
    required this.locale,
    required this.onLocaleChanged,
    required this.onComplete,
    super.key,
  });

  final AppStrings strings;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => onLocaleChanged(
                    Locale(strings.isArabic ? 'en' : 'ar'),
                  ),
                  child: Text(strings.languageLabel),
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FocusXColors.green.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: FocusXColors.green.withValues(alpha: 0.12),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: FocusXColors.green,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'FOCUSX',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: FocusXColors.green,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.text('onboarding_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                strings.text('onboarding_body'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FocusXColors.muted,
                      height: 1.6,
                    ),
              ),
              const SizedBox(height: 28),
              FocusXCard(
                child: Row(
                  children: [
                    const Icon(Icons.spa_outlined, color: FocusXColors.violet),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.text('onboarding_step'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryAction(
                label: strings.text('get_started'),
                icon: Icons.arrow_forward_rounded,
                onPressed: onComplete,
              ),
              const SizedBox(height: 12),
              Text(
                strings.text('offline_label'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusXColors.muted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
