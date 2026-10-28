import 'package:flutter_test/flutter_test.dart';

import 'package:focusx/services/platform_restrictions.dart';

void main() {
  test('keeps App Blocked distinct from an unreached or unsupported limit', () {
    final app = RestrictedApp.fromMap(<Object?, Object?>{
      'id': 'opaque-token',
      'name': 'Selected app 1',
      'dailyLimitMinutes': 30,
      'enabled': true,
      'state': 'appBlocked',
    });

    expect(app.state, CapabilityState.appBlocked);
    expect(app.usedMinutes, isNull);
    expect(app.remainingMinutes, isNull);
  });

  test('unknown native states become integration errors, not success', () {
    final app = RestrictedApp.fromMap(<Object?, Object?>{
      'id': 'app',
      'name': 'App',
      'state': 'active_without_verification',
    });

    expect(app.state, CapabilityState.integrationError);
  });

  test('decodes native capability state and real usage only when supplied', () {
    final status = IntegrationStatus.fromMap(<Object?, Object?>{
      'platform': 'Android',
      'authorization': 'supported',
      'capabilities': <Object?>[
        <Object?, Object?>{
          'name': 'appBlocking',
          'state': 'unsupported',
        },
      ],
      'apps': <Object?>[
        <Object?, Object?>{
          'id': 'com.instagram.android',
          'name': 'Instagram',
          'dailyLimitMinutes': 30,
          'enabled': true,
          'usedMinutes': 22,
          'remainingMinutes': 8,
          'state': 'unsupported',
        },
      ],
    });

    expect(status.authorization, CapabilityState.supported);
    expect(status.capabilities.single.state, CapabilityState.unsupported);
    expect(status.apps.single.usedMinutes, 22);
    expect(status.apps.single.remainingMinutes, 8);
  });
}
