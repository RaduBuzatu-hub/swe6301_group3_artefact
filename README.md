# swe6301_group3_artefact

Flutter web app for the SWE6301 Group 3 artefact.

## Build for presentation (release web)
1. `flutter pub get`
2. `flutter build web --release`
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
