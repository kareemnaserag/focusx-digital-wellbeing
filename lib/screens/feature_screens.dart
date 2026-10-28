import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/platform_restrictions.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LimitsScreen extends StatefulWidget {
  const LimitsScreen({
    required this.strings,
    required this.onOpenIntegration,
    super.key,
  });

  final AppStrings strings;
  final VoidCallback onOpenIntegration;

  @override
  State<LimitsScreen> createState() => _LimitsScreenState();
}

class _LimitsScreenState extends State<LimitsScreen> {
  IntegrationStatus? _status;
  bool _loading = true;
  bool _working = false;
  String? _error;

  AppStrings get strings => widget.strings;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await PlatformRestrictions.getIntegrationStatus(
        languageCode: strings.isArabic ? 'ar' : 'en',
      );
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } on MissingPluginException {
      _setError('native_channel_missing');
    } on UnsupportedError {
      _setError('platform_unsupported');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  Future<void> _selectApps() async {
    setState(() => _working = true);
    try {
      if (Platform.isIOS) {
        await PlatformRestrictions.selectApps(
          languageCode: strings.isArabic ? 'ar' : 'en',
        );
      } else if (Platform.isAndroid) {
        final available = await PlatformRestrictions.getAvailableApps();
        if (!mounted) return;
        final selected = await _chooseAndroidApps(available);
        if (selected == null || selected.isEmpty) return;
        await PlatformRestrictions.selectApps(androidSelection: selected);
      }
      await _refresh();
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } on MissingPluginException {
      _setError('native_channel_missing');
    } on UnsupportedError {
      _setError('platform_unsupported');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<List<AvailableApp>?> _chooseAndroidApps(
    List<AvailableApp> available,
  ) {
    final chosen = <String>{};
    return showDialog<List<AvailableApp>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.text('choose_apps_title')),
          content: SizedBox(
            width: double.maxFinite,
            child: available.isEmpty
                ? Text(strings.text('no_available_apps'))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final app in available)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(app.name),
                          value: chosen.contains(app.id),
                          onChanged: (value) => setDialogState(() {
                            if (value ?? false) {
                              chosen.add(app.id);
                            } else {
                              chosen.remove(app.id);
                            }
                          }),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                available.where((app) => chosen.contains(app.id)).toList(),
              ),
              child: Text(strings.text('done')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLimit(RestrictedApp app) async {
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) {
        var minutes = app.dailyLimitMinutes.clamp(5, 360).toInt();
        var enabled = app.enabled;
        var hour = app.resetHour;
        var minute = app.resetMinute;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(strings.text('edit_limit')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${strings.text('limit_minutes')}: $minutes'),
                  Slider(
                    value: minutes.toDouble(),
                    min: 5,
                    max: 360,
                    divisions: 71,
                    label: '$minutes',
                    onChanged: (value) =>
                        setDialogState(() => minutes = value.round()),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.text('enable_limit')),
                    value: enabled,
                    onChanged: (value) =>
                        setDialogState(() => enabled = value),
                  ),
                  const SizedBox(height: 8),
                  Text(strings.text('daily_reset')),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: hour,
                          isExpanded: true,
                          items: [
                            for (var value = 0; value < 24; value++)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => hour = value ?? hour,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(':'),
                      ),
                      Expanded(
                        child: DropdownButton<int>(
                          value: minute,
                          isExpanded: true,
                          items: [
                            for (final value in [0, 15, 30, 45])
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: (value) => setDialogState(
                            () => minute = value ?? minute,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings.text('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'minutes': minutes,
                  'enabled': enabled,
                  'hour': hour,
                  'minute': minute,
                }),
                child: Text(strings.text('save')),
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    setState(() => _working = true);
    try {
      await PlatformRestrictions.configureAppLimit(
        appId: app.id,
        dailyLimitMinutes: result['minutes']! as int,
        enabled: result['enabled']! as bool,
        resetHour: result['hour']! as int,
        resetMinute: result['minute']! as int,
        languageCode: strings.isArabic ? 'ar' : 'en',
      );
      await _refresh();
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } on MissingPluginException {
      _setError('native_channel_missing');
    } on UnsupportedError {
      _setError('platform_unsupported');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _toggleLimit(RestrictedApp app, bool enabled) async {
    setState(() => _working = true);
    try {
      await PlatformRestrictions.configureAppLimit(
        appId: app.id,
        dailyLimitMinutes: app.dailyLimitMinutes,
        enabled: enabled,
        resetHour: app.resetHour,
        resetMinute: app.resetMinute,
        languageCode: strings.isArabic ? 'ar' : 'en',
      );
      await _refresh();
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } on MissingPluginException {
      _setError('native_channel_missing');
    } on UnsupportedError {
      _setError('platform_unsupported');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageList(
      children: [
        _Intro(
          strings: strings,
          title: 'daily_limits',
          body: 'limits_manage_intro',
        ),
        if (Platform.isAndroid)
          PrototypeNotice(message: strings.text('android_blocking_limit')),
        if (Platform.isIOS)
          PrototypeNotice(message: strings.text('ios_selection_privacy')),
        Row(
          children: [
            Expanded(
              child: Text(
                _status == null
                    ? strings.text('device_status')
                    : '${_status!.platform} · ${_stateLabel(_status!.authorization)}',
                style: const TextStyle(
                  color: FocusXColors.muted,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              tooltip: strings.text('refresh_status'),
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: strings.text('integration'),
              onPressed: widget.onOpenIntegration,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        if (_error != null)
          EmptyState(
            title: strings.text('integration_error'),
            body: '${strings.text('usage_unavailable')}\n${_error!}',
            icon: Icons.error_outline_rounded,
          ),
        if (_loading || _working) const LinearProgressIndicator(),
        SectionHeading(
          strings.text('daily_limits'),
          trailing: IconButton(
            onPressed: _working ? null : _selectApps,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: strings.text('select_apps'),
          ),
        ),
        if (!_loading && (_status?.apps.isEmpty ?? true))
          EmptyState(
            title: strings.text('selected_apps_empty'),
            body: strings.text('selected_apps_hint'),
            icon: Icons.apps_rounded,
          ),
        for (final app in _status?.apps ?? const <RestrictedApp>[]) ...[
          _ManagedAppCard(
            app: app,
            strings: strings,
            onEdit: () => _editLimit(app),
            onToggle: (enabled) => _toggleLimit(app, enabled),
          ),
          const SizedBox(height: 10),
        ],
        if (_status?.authorization == CapabilityState.permissionRequired)
          PrimaryAction(
            label: strings.text('open_device_settings'),
            icon: Icons.security_rounded,
            onPressed: widget.onOpenIntegration,
          ),
      ],
    );
  }

  String _stateLabel(CapabilityState state) => strings.text(switch (state) {
        CapabilityState.supported => 'supported',
        CapabilityState.permissionRequired => 'permission_required',
        CapabilityState.entitlementRequired => 'entitlement_required',
        CapabilityState.unsupported => 'not_supported',
        CapabilityState.notImplemented => 'not_implemented',
        CapabilityState.activeMonitoring => 'active_monitoring',
        CapabilityState.limitReached => 'limit_reached',
        CapabilityState.appBlocked => 'app_blocked',
        CapabilityState.integrationError => 'integration_error',
      });
}

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    required this.strings,
    required this.onPreviewAction,
    super.key,
  });

  final AppStrings strings;
  final VoidCallback onPreviewAction;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _selectedMinutes = 25;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return _PageList(
      children: [
        _Intro(strings: strings, title: 'focus_timer', body: 'focus_intro'),
        FocusXCard(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
          gradient: LinearGradient(
            colors: [
              FocusXColors.violet.withValues(alpha: 0.13),
              FocusXColors.surface,
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.center_focus_strong_rounded,
                  size: 28, color: FocusXColors.green),
              const SizedBox(height: 18),
              Text(
                '$_selectedMinutes:00',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(height: 8),
              PreviewBadge(label: strings.text('feature_preview')),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _PresetChip(
                    label: strings.text('preset_25'),
                    selected: _selectedMinutes == 25,
                    onTap: () => setState(() => _selectedMinutes = 25),
                  ),
                  _PresetChip(
                    label: strings.text('preset_45'),
                    selected: _selectedMinutes == 45,
                    onTap: () => setState(() => _selectedMinutes = 45),
                  ),
                  _PresetChip(
                    label: strings.text('preset_60'),
                    selected: _selectedMinutes == 60,
                    onTap: () => setState(() => _selectedMinutes = 60),
                  ),
                  _PresetChip(
                    label: strings.text('custom_duration'),
                    selected: false,
                    onTap: widget.onPreviewAction,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryAction(
                label: strings.text('start'),
                icon: Icons.play_arrow_rounded,
                onPressed: widget.onPreviewAction,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onPreviewAction,
                      child: Text(strings.text('pause')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onPreviewAction,
                      child: Text(strings.text('reset')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionHeading(strings.text('session_history')),
        EmptyState(
          title: strings.text('no_sessions'),
          body: strings.text('session_empty_hint'),
        ),
      ],
    );
  }
}

class DetoxScreen extends StatelessWidget {
  const DetoxScreen({
    required this.strings,
    required this.onPreviewAction,
    super.key,
  });

  final AppStrings strings;
  final VoidCallback onPreviewAction;

  @override
  Widget build(BuildContext context) {
    return _PageList(
      children: [
        _Intro(strings: strings, title: 'schedule_title', body: 'schedule_intro'),
        PrototypeNotice(message: strings.text('preview_action')),
        PrimaryAction(
          label: strings.text('new_schedule'),
          icon: Icons.add_rounded,
          onPressed: onPreviewAction,
        ),
        SectionHeading(strings.text('schedule_title')),
        _ScheduleCard(
          strings: strings,
          title: 'schedule_morning',
          icon: Icons.wb_sunny_outlined,
          color: FocusXColors.green,
          onTap: onPreviewAction,
        ),
        const SizedBox(height: 12),
        _ScheduleCard(
          strings: strings,
          title: 'schedule_evening',
          icon: Icons.nightlight_outlined,
          color: FocusXColors.violet,
          onTap: onPreviewAction,
        ),
      ],
    );
  }
}

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({
    required this.strings,
    required this.onPreviewAction,
    super.key,
  });

  final AppStrings strings;
  final VoidCallback onPreviewAction;

  @override
  Widget build(BuildContext context) {
    return _PageList(
      children: [
        _Intro(strings: strings, title: 'habits_title', body: 'habits_intro'),
        _ChallengeCard(
          strings: strings,
          title: 'challenge_1',
          body: 'challenge_1_desc',
          icon: Icons.hourglass_bottom_rounded,
          color: FocusXColors.green,
          onTap: onPreviewAction,
        ),
        const SizedBox(height: 12),
        _ChallengeCard(
          strings: strings,
          title: 'challenge_2',
          body: 'challenge_2_desc',
          icon: Icons.wb_twilight_rounded,
          color: FocusXColors.violet,
          onTap: onPreviewAction,
        ),
        const SizedBox(height: 12),
        _ChallengeCard(
          strings: strings,
          title: 'challenge_3',
          body: 'challenge_3_desc',
          icon: Icons.self_improvement_rounded,
          color: const Color(0xFFFFC56B),
          onTap: onPreviewAction,
        ),
      ],
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({required this.strings, super.key});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return _PageList(
      children: [
        _Intro(strings: strings, title: 'stats_title', body: 'stats_intro'),
        PrototypeNotice(message: strings.text('stats_sample_note')),
        SectionHeading(strings.text('daily_trend')),
        const _SampleBars(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: strings.text('weekly_average'),
                value:
                    '2 ${strings.text('hours_unit')} 18 ${strings.text('minutes_unit')}',
                icon: Icons.timelapse_rounded,
                color: FocusXColors.violet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryMetric(
                label: strings.text('best_day'),
                value: strings.isArabic ? 'الأربعاء' : 'Wednesday',
                icon: Icons.star_outline_rounded,
                color: FocusXColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryMetric(
          label: strings.text('focus_this_week'),
          value:
              '3 ${strings.text('hours_unit')} 25 ${strings.text('minutes_unit')}',
          icon: Icons.center_focus_strong_rounded,
          color: FocusXColors.green,
        ),
        SectionHeading(strings.text('empty_title')),
        EmptyState(
          title: strings.text('empty_title'),
          body: strings.text('empty_body'),
          icon: Icons.insights_outlined,
        ),
      ],
    );
  }
}

class IntegrationScreen extends StatefulWidget {
  const IntegrationScreen({
    required this.strings,
    required this.onOpenLimits,
    super.key,
  });

  final AppStrings strings;
  final VoidCallback onOpenLimits;

  @override
  State<IntegrationScreen> createState() => _IntegrationScreenState();
}

class _IntegrationScreenState extends State<IntegrationScreen>
    with WidgetsBindingObserver {
  late Future<IntegrationStatus> _status;
  bool _requesting = false;

  AppStrings get strings => widget.strings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _status = _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _status = _loadStatus());
    }
  }

  Future<IntegrationStatus> _loadStatus() {
    return PlatformRestrictions.getIntegrationStatus(
      languageCode: strings.isArabic ? 'ar' : 'en',
    );
  }

  Future<void> _requestAuthorization() async {
    setState(() => _requesting = true);
    try {
      await PlatformRestrictions.requestAuthorization();
      if (mounted) {
        setState(() => _status = _loadStatus());
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _status = Future.error(
            StateError(error.message ?? error.code),
            StackTrace.current,
          );
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _status = Future.error(
            StateError('native_channel_missing'),
            StackTrace.current,
          );
        });
      }
    } on UnsupportedError {
      if (mounted) {
        setState(() {
          _status = Future.error(
            StateError('platform_unsupported'),
            StackTrace.current,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  String _capabilityLabel(String name) => strings.text(switch (name) {
        'usageAccess' => 'cap_usage_access',
        'appSelection' => 'cap_app_selection',
        'appBlocking' => 'cap_app_blocking',
        'backgroundMonitoring' => 'cap_monitoring',
        _ => name,
      });

  String _stateLabel(CapabilityState state) => strings.text(switch (state) {
        CapabilityState.supported => 'supported',
        CapabilityState.permissionRequired => 'permission_required',
        CapabilityState.entitlementRequired => 'entitlement_required',
        CapabilityState.unsupported => 'not_supported',
        CapabilityState.notImplemented => 'not_implemented',
        CapabilityState.activeMonitoring => 'active_monitoring',
        CapabilityState.limitReached => 'limit_reached',
        CapabilityState.appBlocked => 'app_blocked',
        CapabilityState.integrationError => 'integration_error',
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IntegrationStatus>(
      future: _status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        return _PageList(
          children: [
            _Intro(
              strings: strings,
              title: 'device_status',
              body: 'device_status_intro',
            ),
            if (Platform.isAndroid)
              PrototypeNotice(
                message: strings.text('usage_access_explanation'),
              ),
            if (Platform.isAndroid)
              PrototypeNotice(
                message: strings.text('android_blocking_limit'),
              ),
            if (snapshot.hasError)
              EmptyState(
                title: strings.text('integration_error'),
                body:
                    '${strings.text('integration_error_body')}\n${snapshot.error}',
                icon: Icons.error_outline_rounded,
              ),
            if (snapshot.connectionState == ConnectionState.waiting ||
                _requesting)
              const LinearProgressIndicator(),
            if (status != null) ...[
              SectionHeading(
                strings.text('integration'),
                trailing: IconButton(
                  tooltip: strings.text('refresh_status'),
                  onPressed: () => setState(
                    () => _status = _loadStatus(),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              for (final capability in status.capabilities) ...[
                _CapabilityRow(
                  title: _capabilityLabel(capability.name),
                  subtitle: status.platform,
                  status: _stateLabel(capability.state),
                ),
                const SizedBox(height: 10),
              ],
              if (Platform.isIOS &&
                  status.authorization == CapabilityState.entitlementRequired)
                PrototypeNotice(message: strings.text('ios_entitlement_help')),
              if (Platform.isIOS &&
                  status.capabilities.any(
                    (item) =>
                        item.name == 'appBlocking' &&
                        item.state == CapabilityState.integrationError,
                  ))
                PrototypeNotice(
                  message: strings.text('ios_extensions_missing'),
                ),
              if (Platform.isIOS &&
                  status.authorization == CapabilityState.supported &&
                  status.capabilities.every(
                    (item) =>
                        item.name != 'appBlocking' ||
                        item.state != CapabilityState.integrationError,
                  ))
                PrototypeNotice(
                  message: strings.text('ios_usage_limitation'),
                ),
              if (status.platform == 'Android')
                PrototypeNotice(message: strings.text('android_usage_only')),
              if (status.authorization == CapabilityState.permissionRequired ||
                  status.authorization == CapabilityState.integrationError)
                PrimaryAction(
                  label: Platform.isAndroid
                      ? strings.text('open_device_settings')
                      : strings.text('authorize_device'),
                  icon: Icons.security_rounded,
                  onPressed: _requestAuthorization,
                ),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 12),
                PrimaryAction(
                  label: strings.text('select_apps'),
                  icon: Icons.apps_rounded,
                  onPressed: widget.onOpenLimits,
                ),
              ],
            ],
            SectionHeading(strings.text('daily_limits')),
            OutlinedButton.icon(
              onPressed: widget.onOpenLimits,
              icon: const Icon(Icons.tune_rounded),
              label: Text(strings.text('manage_limits')),
            ),
          ],
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.strings,
    required this.onLocaleChanged,
    required this.onPreviewAction,
    required this.onOpenIntegration,
    super.key,
  });

  final AppStrings strings;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback onPreviewAction;
  final VoidCallback onOpenIntegration;

  @override
  Widget build(BuildContext context) {
    return _PageList(
      children: [
        _Intro(strings: strings, title: 'privacy_title', body: 'privacy_intro'),
        FocusXCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.text('privacy_notice'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                strings.text('privacy_body'),
                style: const TextStyle(
                    color: FocusXColors.muted, height: 1.5),
              ),
            ],
          ),
        ),
        SectionHeading(strings.text('settings')),
        FocusXCard(
          child: Row(
            children: [
              const Icon(Icons.translate_rounded, color: FocusXColors.green),
              const SizedBox(width: 12),
              Expanded(child: Text(strings.text('language'))),
              TextButton(
                onPressed: () => onLocaleChanged(
                  Locale(strings.isArabic ? 'en' : 'ar'),
                ),
                child: Text(strings.languageLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SettingsAction(
          icon: Icons.file_upload_outlined,
          label: strings.text('export_data'),
          onTap: onPreviewAction,
        ),
        const SizedBox(height: 10),
        _SettingsAction(
          icon: Icons.delete_outline_rounded,
          label: strings.text('delete_data'),
          onTap: onPreviewAction,
        ),
        SectionHeading(strings.text('integration')),
        _SettingsAction(
          icon: Icons.phonelink_setup_rounded,
          label: strings.text('device_status'),
          onTap: onOpenIntegration,
        ),
      ],
    );
  }
}

class _PageList extends StatelessWidget {
  const _PageList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: children,
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.strings,
    required this.title,
    required this.body,
  });

  final AppStrings strings;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.text(title),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            strings.text(body),
            style: const TextStyle(color: FocusXColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ManagedAppCard extends StatelessWidget {
  const _ManagedAppCard({
    required this.app,
    required this.strings,
    required this.onEdit,
    required this.onToggle,
  });

  final RestrictedApp app;
  final AppStrings strings;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  String _statusLabel() => strings.text(switch (app.state) {
        CapabilityState.supported => 'supported',
        CapabilityState.permissionRequired => 'permission_required',
        CapabilityState.entitlementRequired => 'entitlement_required',
        CapabilityState.unsupported => 'not_supported',
        CapabilityState.notImplemented => 'not_implemented',
        CapabilityState.activeMonitoring => 'active_monitoring',
        CapabilityState.limitReached => 'limit_reached',
        CapabilityState.appBlocked => 'app_blocked',
        CapabilityState.integrationError => 'integration_error',
      });

  String _duration(int? minutes) {
    if (minutes == null) return '—';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder ${strings.text('minutes_unit')}';
    return '$hours ${strings.text('hours_unit')} $remainder ${strings.text('minutes_unit')}';
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = switch (app.state) {
      CapabilityState.appBlocked => const Color(0xFFFF7777),
      CapabilityState.activeMonitoring => FocusXColors.green,
      CapabilityState.limitReached => FocusXColors.violet,
      _ => FocusXColors.muted,
    };
    return FocusXCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apps_rounded, color: FocusXColors.violet),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  app.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: strings.text('edit_limit'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              Switch(
                value: app.enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: stateColor),
              Text(
                _statusLabel(),
                style: TextStyle(
                  color: stateColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '· ${app.dailyLimitMinutes} ${strings.text('minutes_unit')}',
                style: const TextStyle(
                  color: FocusXColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeValue(
                  label: strings.text('used_today'),
                  value: _duration(app.usedMinutes),
                ),
              ),
              Expanded(
                child: _TimeValue(
                  label: strings.text('time_left'),
                  value: _duration(app.remainingMinutes),
                ),
              ),
              Expanded(
                child: _TimeValue(
                  label: strings.text('daily_reset'),
                  value:
                      '${app.resetHour.toString().padLeft(2, '0')}:${app.resetMinute.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeValue extends StatelessWidget {
  const _TimeValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: FocusXColors.muted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({
    required this.label,
    required this.onPreviewAction,
  });

  final String label;
  final VoidCallback onPreviewAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.notifications_none_rounded,
            color: FocusXColors.violet, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Switch(value: false, onChanged: (_) => onPreviewAction()),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: FocusXColors.green.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: selected ? FocusXColors.green : Colors.white,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? FocusXColors.green : FocusXColors.divider,
      ),
      backgroundColor: FocusXColors.surface,
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.strings,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final AppStrings strings;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(strings.text(title),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Switch(value: false, onChanged: (_) => onTap()),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${strings.text('schedule_days')} · ${strings.text('schedule_time')}',
              style: const TextStyle(color: FocusXColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.strings,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final AppStrings strings;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 16),
          Text(strings.text(title),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            strings.text(body),
            style: const TextStyle(color: FocusXColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onTap,
            child: Text(strings.text('join_challenge')),
          ),
        ],
      ),
    );
  }
}

class _SampleBars extends StatelessWidget {
  const _SampleBars();

  @override
  Widget build(BuildContext context) {
    const data = [0.42, 0.65, 0.3, 0.84, 0.57, 0.25, 0.48];
    return FocusXCard(
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data
              .map(
                (value) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: FractionallySizedBox(
                      heightFactor: value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: FocusXColors.violet.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(color: FocusXColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.circle_outlined, color: FocusXColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: FocusXColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: FocusXColors.violet,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FocusXCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: FocusXColors.green),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
