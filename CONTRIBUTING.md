# Contributing to FOCUSX

Thank you for your interest in improving FOCUSX.

## Before you begin

- Check existing issues and changes to avoid duplicating work.
- For significant behavior or native-integration changes, open an issue first to discuss scope.
- Never include API keys, personal data, signing credentials, provisioning profiles, or device usage records.

## Development

1. Install Flutter 3.27 or later and the platform toolchains you intend to change.
2. Generate platform runners as described in [README.md](README.md), preserving the supplied native integration sources.
3. Run `flutter pub get`, `flutter analyze`, and `flutter test`.
4. For Android changes, build and test with Usage Access both granted and revoked.
5. For Screen Time changes, test on a physical iPhone with correctly configured Family Controls entitlements and all required extensions.

## Pull requests

- Keep changes focused and preserve Arabic RTL and English LTR behavior.
- Include tests for changed logic and update setup/capability documentation.
- Clearly distinguish supported behavior from prototypes and platform limitations.
- Do not state that an app is blocked unless the operating system confirms an applied shield.
- Describe the devices, OS versions, commands, and results used for validation.

## License

The owner has chosen not to license this source for reuse. Please do not redistribute or publish derived copies.
