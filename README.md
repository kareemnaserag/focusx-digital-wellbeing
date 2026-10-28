# FOCUSX — Digital Wellbeing

FOCUSX is an Arabic-first Flutter project for digital wellbeing, focus sessions, and social-media screen-time management. The shared UI supports Arabic RTL and English LTR. Platform-specific capabilities use explicit Flutter method channels for iOS Screen Time and Android usage access.

**Suggested repository:** `focusx-digital-wellbeing`  
**Description:** FOCUSX — A cross-platform digital wellbeing app for screen-time management, focus sessions, and social media usage control.

> **Project status:** Source scaffold and native integration sources are provided. This folder does not yet contain generated Flutter platform runners, an Xcode project, or Gradle wrapper. Native code and app UI have not been built or tested on devices. Do not treat this repository as a finished or installable app.

## Features

- Dark Arabic-first Flutter interface with English localization, onboarding, dashboard, limits, focus, detox, habits, statistics, device status, and privacy screens.
- App-limit interface with selected-app list, daily limits, reset time, and explicit capability/status reporting.
- Android Kotlin source for opt-in Usage Access, selected social-app usage summaries, and local limit preferences.
- iOS Swift source for Family Controls authorization, Apple's app picker, DeviceActivity threshold monitoring, ManagedSettings shields, and shield configuration/actions.
- Typed Flutter/native contract and initial widget/model tests.

### Implemented vs. not yet verified

| Area | Current status |
|---|---|
| Flutter UI and Arabic/English localization | Implemented in source; Flutter tests/build not run in this environment |
| Android usage reads | Kotlin implementation is provided; requires generated runner, permission, and physical-device validation |
| Android app blocking | **Not supported** for ordinary Android apps; a limit reached is not a block |
| iOS limit monitoring and shields | Swift implementation is provided; requires Xcode extension targets, entitlements, signing, embedding, and physical-device validation |
| iOS live usage/remaining time | Not exposed through the current Flutter contract; no sample values are presented as actual usage |
| Timer lifecycle/persistence, detox schedules, cloud sync | Not implemented |
| Installable Android/iOS builds | Not generated |
| Public web preview | Static Arabic RTL interface preview is published with GitHub Pages from `docs/`; its timer is local to the browser and native usage/blocking features are unavailable on the web |

Sample analytics shown elsewhere in the UI remain prototype content and must not be interpreted as device usage.

## Requirements

- Flutter 3.27 or later and Dart from the matching Flutter SDK.
- Android Studio/Android SDK for Android builds.
- Full Xcode and Apple Developer signing setup for iOS builds and Screen Time extensions.
- Physical devices for validating Usage Access and Screen Time monitoring/shields.

## Setup

The source directory did not include generated platform runners. Start by generating them:

```sh
flutter create --platforms=android,ios --org=com.focusx --project-name=focusx .
```

Review the generated platform files carefully. Preserve and merge the supplied `AppDelegate.swift`, `MainActivity.kt`, and Android manifest additions; do not overwrite the native integration code. Then:

```sh
flutter pub get
flutter analyze
flutter test
```

## Platform integration requirements

### Android

`UsageStatsManager` requires the user to grant **Usage Access** in Android Settings. This permission allows reading app-use duration and does not permit blocking another app. The supplied Kotlin bridge reports app blocking and background enforcement as unsupported. FOCUSX deliberately avoids Accessibility-based blocking, overlays, and misleading notifications.

Merge the supplied `PACKAGE_USAGE_STATS` declaration and package queries from `android/app/src/main/AndroidManifest.xml` into the generated manifest. Build and verify usage calculations with permission granted and revoked, including app restart and reset-time boundaries. A limit reached is not equivalent to an app being blocked.

### iOS / Screen Time

The iOS implementation uses `FamilyControls`, `DeviceActivity`, and `ManagedSettings`; it is not operational until configured in Xcode.

1. Set the Runner bundle ID to `com.focusx.focusx`.
2. Add iOS extension targets for `DeviceActivityMonitor`, `ShieldConfiguration`, and `ShieldAction`, using the corresponding supplied source, `Info.plist`, and entitlements under `ios/`.
3. Add `ios/FocusXShared/FocusXShared.swift` to Runner and DeviceActivityMonitor target membership. Embed all three extensions in Runner.
4. Enable Family Controls and App Groups for the appropriate targets; the shared group identifier is `group.com.focusx.focusx`.
5. Request Apple's Family Controls distribution entitlement before an App Store/TestFlight distribution build. Approval is not automatic.
6. On a physical iPhone, test authorization, selection, threshold crossing, shield display, daily reset, relaunch/reboot, and authorization revocation. Simulator testing alone does not establish real Screen Time behavior.

The system picker intentionally keeps selected app identities opaque. The app can show a generic selected-app label; it does not infer a package name. DeviceActivity thresholds do not provide live numeric totals through this integration, so usage and remaining-time values are not fabricated.

References: [Apple FamilyControls](https://developer.apple.com/documentation/familycontrols), [DeviceActivity](https://developer.apple.com/documentation/deviceactivity), [ManagedSettings](https://developer.apple.com/documentation/managedsettings), and [request Family Controls distribution access](https://developer.apple.com/contact/request/family-controls-distribution).

## Flutter/native contract

`lib/services/platform_restrictions.dart` defines the shared platform interface:

- `getCapabilities()`
- `requestAuthorization()`
- `getSelectedApps()` / `selectApps()`
- `getUsageSummary()`
- `configureAppLimit()`
- `startDetoxSchedule()` / `stopDetoxSchedule()`
- `getIntegrationStatus()`

iOS uses `focusx/screen_time`; Android uses `focusx/usage_access`. Unsupported features return an explicit state. Platform errors are surfaced instead of being presented as success.

## Tests and builds

Run Flutter checks with:

```sh
flutter analyze
flutter test
flutter build apk
flutter build appbundle
flutter build ios
```

These commands have **not** been run here because Flutter/Dart, generated runners, device SDK configuration, and full Xcode are unavailable. iOS release distribution additionally requires Apple signing, provisioning, Family Controls entitlement approval, and correctly embedded extensions. An unsigned build is not a public-installable iOS app.

## Screenshots and preview

The public web preview is available at https://kareemnaserag.github.io/focusx-digital-wellbeing/. It is a static showcase of the FOCUSX interface, not a Flutter web build or installable mobile app. Usage figures are sample content; native Screen Time and Android usage integrations are not available on the website.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development, testing, and pull request guidance.

## License

The owner has chosen not to include an open-source license. Public visibility does not grant permission to reuse, modify, or redistribute the source; all rights remain reserved.
