# Android release signing

The release build is signed with a keystore that is **never committed**. Without
it the build still works, but falls back to the debug key — fine for local
testing, rejected by Google Play, and unsafe to distribute (the debug key is a
well-known key shared by every Android SDK install, so anyone can forge a build
that looks like the same app).

## One-time: create the keystore

Run from `android/`. Choose a strong password and use the same one for both
prompts unless you have a reason not to.

```bash
keytool -genkey -v \
  -keystore fitbox-release.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias fitbox
```

Then create `android/key.properties`:

```properties
storePassword=<the password you chose>
keyPassword=<the key password>
keyAlias=fitbox
storeFile=fitbox-release.jks
```

Both `fitbox-release.jks` and `key.properties` are gitignored.

## ⚠ Back the keystore up before you publish

**Whatever key first publishes the app is the only key that can ever update
it.** Lose it and you cannot ship an update to existing users — the only way out
is a new listing under a new package name, losing every install and review.

Keep a copy of `fitbox-release.jks` **and** its passwords somewhere durable and
private: a password manager entry, an encrypted backup, or both. Not in this
repository, and not only on this laptop.

Enrolling in **Play App Signing** when you first upload is strongly recommended:
Google then holds the signing key and your upload key can be reset if lost.

## Build

```bash
flutter build appbundle --release   # build/app/outputs/bundle/release — upload this to Play
flutter build apk --release         # build/app/outputs/flutter-apk — for direct install/testing
```

Verify what actually signed an APK:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

`Owner: CN=Android Debug` means the fallback was used and the build is **not**
publishable.

## ⚠ Register the release SHA-1 in Firebase, or Google Sign-In breaks

Google Sign-In authorises an app by its **signing certificate**. Only the debug
certificate was registered in Firebase, so a build signed with the release key is
a different app as far as Google is concerned and **"Continue with Google" will
fail** until its fingerprint is added.

Current release certificate:

```
SHA-1:   A8:3D:92:45:9D:69:79:5F:4A:B1:6D:0E:25:02:D4:D5:2B:96:01:60
SHA-256: 2C:3F:3B:FF:42:37:DC:85:68:54:DC:46:45:27:F9:10:AF:52:C6:1A:B9:94:11:C9:95:D1:EC:95:F2:6B:1E:ED
```

Add both in **Firebase console → Project settings → Your apps → Android →
Add fingerprint**, then download the refreshed `google-services.json` and replace
`android/app/google-services.json`. Keep the debug fingerprint registered too, so
debug builds keep working.

Re-read the fingerprints at any time with:

```bash
keytool -list -v -keystore fitbox-release.jks -alias fitbox
```

If you later enrol in Play App Signing, Google re-signs your upload with *their*
key — register that fingerprint from the Play Console as well.

## Also needed for a real store release

- `android/local.properties` → `MAPS_API_KEY=...` (gitignored; maps are blank without it)
- `android/app/google-services.json` from Firebase (gitignored; the build fails without it)
- Play Console: store listing, screenshots, content rating, Data Safety form, and
  a privacy policy URL — https://www.fitboxsports.in/privacy
