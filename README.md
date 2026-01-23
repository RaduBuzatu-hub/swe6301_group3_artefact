# swe6301_group3_artefact

Flutter web app for the SWE6301 Group 3 artefact.

## Examiner quick access
- Hosted web app: `https://radubuzatu-hub.github.io/swe6301_group3_artefact/`
- Android APK install (if provided as `app-release.apk`):
  1. Copy `app-release.apk` to an Android phone.
  2. Open the file and allow "Install unknown apps" if prompted.
  3. Launch the app after installation completes.
- Run from source (IDE or terminal):
  1. Install Flutter SDK (3.10+).
  2. `flutter pub get`
  3. `flutter run -d chrome` (web) or `flutter run` with a device/emulator.

## Build for presentation (release web)
1. `flutter pub get`
2. `flutter build web --release --base-href /swe6301_group3_artefact/`
3. Serve `build/web` with a static server (example below), then open
   `http://localhost:8080` in a browser.
   - `Set-Location build/web`
   - `python -m http.server 8080`

## Run locally (web)
- `flutter run -d chrome`
- More options and troubleshooting: `docs/LOCAL_WEB_RUN.md`

## Firebase
This app uses Firebase Auth and Firestore. The default config is in
`lib/firebase_options.dart` for project `swe6301group3`. If you do not have
access, ask the team for access or reconfigure with FlutterFire.
