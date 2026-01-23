# Local Web Run

## Prereqs
- Flutter SDK 3.10+ (includes Dart)
- Chrome or another Chromium browser for `flutter run -d chrome`
- Optional: Python 3 if you want to serve the compiled build

## Option A: Run from source (dev)
1. `flutter pub get`
2. `flutter run -d chrome`

You can also run a local web server:
1. `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080`
2. Open `http://localhost:8080`

## Option B: Run compiled build (presentation)
1. `flutter build web --release`
2. `Set-Location build/web`
3. `python -m http.server 8080`
4. Open `http://localhost:8080`

## Firebase note
This app uses Firebase Auth and Firestore. The default config is in
`lib/firebase_options.dart` for project `swe6301group3`. If you do not have
access, ask the team for access or reconfigure with FlutterFire.
