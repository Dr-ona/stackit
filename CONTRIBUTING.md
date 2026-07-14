# Contributing to Stackit

## Branch workflow

Create each change from an up-to-date `main` branch and keep one focused change
per branch and pull request.

- `feature/<name>` for user-facing capabilities
- `fix/<name>` for bug fixes
- `chore/<name>` for maintenance and tooling

Before opening a pull request, run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Pull requests target `main` and must pass the **Flutter CI / Verify and build
Android** check before merging.

## Versions

Stackit follows semantic versioning:

- Patch releases fix existing behavior.
- Minor releases add backward-compatible capabilities.
- Major releases may introduce breaking changes.

Flutter build numbers follow the version after `+` in `pubspec.yaml` and must
increase for every store upload.
