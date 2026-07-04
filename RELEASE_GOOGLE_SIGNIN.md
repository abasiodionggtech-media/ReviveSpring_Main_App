# Google Sign-In Release Checklist

Google Sign-In can work in debug but fail in release when the release certificate is not registered with Google.

## 1. Build with the Web OAuth client ID

Copy `env/release.example.json` to `env/release.json` and put your Web OAuth client ID in both values.

```powershell
flutter build appbundle --release --dart-define-from-file=env/release.json
```

For APK testing:

```powershell
flutter build apk --release --dart-define-from-file=env/release.json
```

## 2. Use a release keystore

Copy `android/key.properties.example` to `android/key.properties` and fill in your keystore values.

`android/key.properties` is ignored by git. Do not share it publicly.

## 3. Add the release SHA to Google

Print the upload-key SHA values:

```powershell
.\tool\print_android_release_sha.ps1
```

Add the SHA-1 and SHA-256 to your Android OAuth client / Firebase Android app for package:

```text
com.example.revive_spring
```

If publishing to Google Play with Play App Signing, also copy the App signing SHA-1 and SHA-256 from Play Console and add those to Google Cloud/Firebase.

## 4. Backend environment

On Render/backend, `GOOGLE_CLIENT_IDS` or `GOOGLE_WEB_CLIENT_ID` must include the same Web OAuth client ID used in `env/release.json`.

## 5. Check project consistency

`android/app/google-services.json` and `env/release.json` must come from the same Firebase/Google Cloud project.

If Google Sign-In shows `Account reauth failed` after choosing an account:

- Open `android/app/google-services.json`.
- Confirm `client[0].oauth_client` is not empty.
- Confirm the Android OAuth client is for package `com.example.revive_spring`.
- Confirm the Android OAuth client has the debug SHA, release upload SHA, and Play App Signing SHA if you publish through Google Play.
- Download a fresh `google-services.json` after adding the SHA values.
- Use the Web OAuth client ID from that same project in `env/release.json` and on Render.

In this repo right now, `google-services.json` has an empty `oauth_client` list. That means the Android OAuth client is not present in the Firebase config yet.
