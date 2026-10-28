import 'package:flutter/material.dart';

import '../app_shell.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.strings,
    required this.onNavigate,
    super.key,
  });

  final AppStrings strings;
  final ValueChanged<AppPage> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.text('today'),
                      style: const TextStyle(color: FocusXColors.muted)),
                  const SizedBox(height: 4),
                  Text(
                    strings.text('good_evening'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            PreviewBadge(label: strings.text('sample_data')),
          ],
        ),
        const SizedBox(height: 18),
        _UsageHero(strings: strings),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.flag_outlined,
                label: strings.text('remaining'),
                value:
                    '1 ${strings.text('hours_unit')} 20 ${strings.text('minutes_unit')}',
                color: FocusXColors.violet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.center_focus_strong_rounded,
                label: strings.text('focus_minutes'),
                value: '45 ${strings.text('minutes_unit')}',
                color: FocusXColors.green,
              ),
            ),
          ],
        ),
        SectionHeading(
          strings.text('app_breakdown'),
          trailing: IconButton(
            onPressed: () => onNavigate(AppPage.integration),
            tooltip: strings.text('connect_device'),
            icon: const Icon(Icons.info_outline_rounded, size: 20),
          ),
        ),
        FocusXCard(
          child: Column(
            children: [
              _AppUsageRow(
                name: strings.text('instagram'),
                minutes: 58,
                total: 180,
                icon: Icons.camera_alt_outlined,
                color: FocusXColors.violet,
              ),
              const SizedBox(height: 18),
              _AppUsageRow(
                name: strings.text('tiktok'),
                minutes: 42,
                total: 180,
                icon: Icons.play_circle_outline_rounded,
                color: FocusXColors.green,
              ),
              const SizedBox(height: 18),
              _AppUsageRow(
                name: strings.text('youtube'),
                minutes: 35,
                total: 180,
                icon: Icons.smart_display_outlined,
                color: const Color(0xFFFF7777),
              ),
            ],
          ),
        ),
        SectionHeading(strings.text('daily_trend')),
        _WeeklyChart(strings: strings),
        SectionHeading(strings.text('small_steps')),
        PrimaryAction(
          label: strings.text('start_focus'),
          icon: Icons.play_arrow_rounded,
          onPressed: () => onNavigate(AppPage.focus),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onNavigate(AppPage.detox),
          icon: const Icon(Icons.spa_outlined),
          label: Text(strings.text('start_detox')),
          style: OutlinedButton.styleFrom(
            foregroundColor: FocusXColors.green,
            minimumSize: const Size.fromHeight(52),
            side: BorderSide(color: FocusXColors.green.withValues(alpha: 0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => onNavigate(AppPage.limits),
          icon: const Icon(Icons.tune_rounded),
          label: Text(strings.text('manage_limits')),
        ),
        const SizedBox(height: 10),
        PrototypeNotice(message: strings.text('connect_hint')),
      ],
    );
  }
}

class _UsageHero extends StatelessWidget {
  const _UsageHero({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [
          FocusXColors.green.withValues(alpha: 0.13),
          FocusXColors.surface,
          FocusXColors.violet.withValues(alpha: 0.08),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.text('usage_today'),
            style: const TextStyle(color: FocusXColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '2',
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(fontWeight: FontWeight.w900, height: 1),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, bottom: 5),
                child: Text(
                  '${strings.text('hours_unit')} 15 ${strings.text('minutes_unit')}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: FocusXColors.muted),
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: FocusXColors.green),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.64,
              minHeight: 8,
              backgroundColor: FocusXColors.elevated,
              valueColor: AlwaysStoppedAnimation(FocusXColors.green),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${strings.text('goal')}: 3 ${strings.text('hours_unit')} 30 ${strings.text('minutes_unit')}',
                style: const TextStyle(color: FocusXColors.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                strings.text('sample_data'),
                style: const TextStyle(
                  color: FocusXColors.violet,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(color: FocusXColors.muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

class _AppUsageRow extends StatelessWidget {
  const _AppUsageRow({
    required this.name,
    required this.minutes,
    required this.total,
    required this.icon,
    required this.color,
  });

  final String name;
  final int minutes;
  final int total;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(name)),
                  Text('$minutes ${strings.text('minutes_unit')}',
                      style: const TextStyle(color: FocusXColors.muted)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: minutes / total,
                  minHeight: 5,
                  backgroundColor: FocusXColors.elevated,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    const values = [0.55, 0.78, 0.42, 0.88, 0.62, 0.35, 0.68];
    final days = strings.isArabic
        ? ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return FocusXCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(strings.text('social_total'),
                  style: const TextStyle(color: FocusXColors.muted)),
              const Spacer(),
              Text(strings.text('sample_data'),
                  style: const TextStyle(
                      color: FocusXColors.violet, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: values[index],
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      FocusXColors.green,
                                      FocusXColors.green
                                          .withValues(alpha: 0.22),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[index],
                            style: const TextStyle(
                                color: FocusXColors.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
