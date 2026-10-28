import 'dart:io';

import 'package:flutter/services.dart';

enum CapabilityState {
  supported,
  permissionRequired,
  entitlementRequired,
  unsupported,
  notImplemented,
  activeMonitoring,
  limitReached,
  appBlocked,
  integrationError,
}

CapabilityState _stateFrom(Object? value) {
  return CapabilityState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => CapabilityState.integrationError,
  );
}

class PlatformCapability {
  const PlatformCapability({
    required this.name,
    required this.state,
    this.message,
  });

  final String name;
  final CapabilityState state;
  final String? message;

  factory PlatformCapability.fromMap(Map<Object?, Object?> map) {
    return PlatformCapability(
      name: map['name'] as String? ?? 'unknown',
      state: _stateFrom(map['state']),
      message: map['message'] as String?,
    );
  }
}

class RestrictedApp {
  const RestrictedApp({
    required this.id,
    required this.name,
    required this.dailyLimitMinutes,
    required this.enabled,
    required this.state,
    this.usedMinutes,
    this.remainingMinutes,
    this.resetHour = 0,
    this.resetMinute = 0,
  });

  final String id;
  final String name;
  final int dailyLimitMinutes;
  final bool enabled;
  final CapabilityState state;
  final int? usedMinutes;
  final int? remainingMinutes;
  final int resetHour;
  final int resetMinute;

  factory RestrictedApp.fromMap(Map<Object?, Object?> map) {
    return RestrictedApp(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'App',
      dailyLimitMinutes: map['dailyLimitMinutes'] as int? ?? 30,
      enabled: map['enabled'] as bool? ?? false,
      state: _stateFrom(map['state']),
      usedMinutes: map['usedMinutes'] as int?,
      remainingMinutes: map['remainingMinutes'] as int?,
      resetHour: map['resetHour'] as int? ?? 0,
      resetMinute: map['resetMinute'] as int? ?? 0,
    );
  }
}

class IntegrationStatus {
  const IntegrationStatus({
    required this.platform,
    required this.authorization,
    required this.capabilities,
    required this.apps,
    this.message,
  });

  final String platform;
  final CapabilityState authorization;
  final List<PlatformCapability> capabilities;
  final List<RestrictedApp> apps;
  final String? message;

  factory IntegrationStatus.fromMap(Map<Object?, Object?> map) {
    return IntegrationStatus(
      platform: map['platform'] as String? ?? 'unknown',
      authorization: _stateFrom(map['authorization']),
      capabilities: ((map['capabilities'] as List<Object?>?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(PlatformCapability.fromMap)
          .toList(),
      apps: ((map['apps'] as List<Object?>?) ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(RestrictedApp.fromMap)
          .toList(),
      message: map['message'] as String?,
    );
  }
}

class AvailableApp {
  const AvailableApp({required this.id, required this.name});

  final String id;
  final String name;

  factory AvailableApp.fromMap(Map<Object?, Object?> map) {
    return AvailableApp(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'App',
    );
  }
}

class PlatformRestrictions {
  PlatformRestrictions._();

  static const _ios = MethodChannel('focusx/screen_time');
  static const _android = MethodChannel('focusx/usage_access');

  static MethodChannel get _channel {
    if (Platform.isIOS) return _ios;
    if (Platform.isAndroid) return _android;
    throw UnsupportedError('FOCUSX device integrations are mobile-only.');
  }

  static Future<List<PlatformCapability>> getCapabilities() async {
    final result =
        await _channel.invokeMapMethod<Object?, Object?>('getCapabilities');
    final values = (result?['capabilities'] as List<Object?>?) ?? const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(PlatformCapability.fromMap)
        .toList();
  }

  static Future<CapabilityState> requestAuthorization() async {
    final result = await _channel
        .invokeMapMethod<Object?, Object?>('requestAuthorization');
    return _stateFrom(result?['state']);
  }

  static Future<List<RestrictedApp>> getSelectedApps() async {
    final result =
        await _channel.invokeMapMethod<Object?, Object?>('getSelectedApps');
    final values = (result?['apps'] as List<Object?>?) ?? const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(RestrictedApp.fromMap)
        .toList();
  }

  static Future<List<AvailableApp>> getAvailableApps() async {
    final result =
        await _channel.invokeMapMethod<Object?, Object?>('getAvailableApps');
    final values = (result?['apps'] as List<Object?>?) ?? const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(AvailableApp.fromMap)
        .toList();
  }

  static Future<List<RestrictedApp>> selectApps({
    List<AvailableApp> androidSelection = const [],
    String languageCode = 'en',
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'selectApps',
      {
        'appIds': androidSelection.map((app) => app.id).toList(),
        'languageCode': languageCode,
      },
    );
    final values = (result?['apps'] as List<Object?>?) ?? const [];
    return values
        .whereType<Map<Object?, Object?>>()
        .map(RestrictedApp.fromMap)
        .toList();
  }

  static Future<Map<String, int>> getUsageSummary() async {
    final result =
        await _channel.invokeMapMethod<Object?, Object?>('getUsageSummary');
    final usage = result?['usageMinutes'];
    if (usage is! Map<Object?, Object?>) return const {};
    return usage.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  static Future<CapabilityState> configureAppLimit({
    required String appId,
    required int dailyLimitMinutes,
    required bool enabled,
    required int resetHour,
    required int resetMinute,
    String languageCode = 'en',
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'configureAppLimit',
      {
        'appId': appId,
        'dailyLimitMinutes': dailyLimitMinutes,
        'enabled': enabled,
        'resetHour': resetHour,
        'resetMinute': resetMinute,
        'languageCode': languageCode,
      },
    );
    return _stateFrom(result?['state']);
  }

  static Future<CapabilityState> startDetoxSchedule(
    Map<String, Object?> schedule,
  ) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'startDetoxSchedule',
      schedule,
    );
    return _stateFrom(result?['state']);
  }

  static Future<CapabilityState> stopDetoxSchedule(String scheduleId) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'stopDetoxSchedule',
      {'scheduleId': scheduleId},
    );
    return _stateFrom(result?['state']);
  }

  static Future<IntegrationStatus> getIntegrationStatus({
    String languageCode = 'en',
  }) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getIntegrationStatus',
      {'languageCode': languageCode},
    );
    return IntegrationStatus.fromMap(result ?? const {});
  }
}
