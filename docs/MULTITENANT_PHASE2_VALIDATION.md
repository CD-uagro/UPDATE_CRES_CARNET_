# Multitenant Flutter Phase 2 Validation

## Commands

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze lib test
flutter test
flutter build windows --release --dart-define=APP_VARIANT=CRES
flutter build windows --release --dart-define=APP_VARIANT=LOYOLA_DEMO
flutter build windows --release --dart-define=APP_VARIANT=MULTITENANT --dart-define=MULTITENANT_API_BASE_URL=https://URL-STAGING
git diff --check
```

## Expected

- CRES remains the default.
- LOYOLA_DEMO local still has no backend requirement.
- MULTITENANT requires a staging API URL.
- MULTITENANT uses `sasu_multitenant` secure-storage keys.
- The build script creates a separate Windows folder and manifest.

## Manual Staging Check

After Render staging exists:

1. Open the generic app.
2. Resolve `LOYOLA-DEMO-2026`.
3. Login with a demo user.
4. Resolve `CRES-STAGING-2026`.
5. Login with a CRES staging user.
6. Confirm no institution can see the other's data.
