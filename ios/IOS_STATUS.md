# iOS — status and what's left

> ✅ **The iOS app compiles, with real configuration.** Verified on Codemagic
> 13 Aug 2026 (workflow `ios-validate`, Mac mini M2): pods resolved, unsigned
> release build succeeded, producing `Runner.app.zip` (~27.7 MB).
>
> Note there were **two** green runs. The first compiled with *empty* config —
> the restore step wrote empty files from unset variables without complaining, so
> the build passed while Firebase config and the Maps key were blank. Guards were
> added (a missing or malformed value now fails the build by name), the variable
> group was filled in, and the second run passed **with** the real
> `GoogleService-Info.plist` and iOS Maps key. That second run is the one that
> means something.
>
> This was the only part that could not be checked from Windows. Everything
> remaining is signing, distribution and device testing — all of which need a
> paid Apple Developer account, not more code.

**Everything that can be done on Windows is done.** The remaining work all needs
macOS (Xcode/CocoaPods) or a paid Apple Developer account, and is intended to run
on **Codemagic** rather than a local Mac — see `../codemagic.yaml`.

The app is one Flutter codebase, so every feature and screen already exists for
iOS. What follows is platform plumbing, not product work. The v1.1.0 owner-review
changes (permanent territory, the two map views, per-run points, owner identity on
the map) are all shared Dart or backend, so they add nothing to this list.

---

## Done (no Mac needed)

| Item | Detail |
|---|---|
| App features & UI | Shared codebase — nothing iOS-specific to rewrite |
| Location permission | `NSLocationWhenInUseUsageDescription` |
| Background running | `UIBackgroundModes: location` — the run keeps recording when backgrounded |
| Motion / steps | `NSMotionUsageDescription` |
| Google Maps | `GMSApiKey` reads the `$(MAPS_API_KEY)` build setting; `AppDelegate.swift` calls `GMSServices.provideAPIKey` |
| Google Sign-In | Firebase iOS app registered; reversed-client-id URL scheme in `Info.plist` |
| App Group | `group.com.fitboxsports.app` — shared container for the widget |
| App icons | Generated into `Assets.xcassets/AppIcon.appiconset` (21 sizes) |
| Deployment target | **iOS 15.0** — the Flutter pod and `firebase_core` 4.x require it (`google_maps_flutter_ios` needs 14.0); `pod install` fails outright below it. Covers iPhone 6s (2015) and later |
| `Podfile` | Written by hand and committed, pinning iOS 15.0 and trimming `permission_handler` to the permissions actually used |
| Flutter version | **Pinned to 3.44.1** in `codemagic.yaml`, not `stable` — a floating version silently changed the iOS deployment floor and broke `pod install` |
| Privacy manifest | `Runner/PrivacyInfo.xcprivacy` — Apple requires it; declares location, email, name, fitness and purchase data plus required-reason API use |
| Export compliance | `ITSAppUsesNonExemptEncryption = false`, so TestFlight stops asking on every upload |
| CI pipeline | `codemagic.yaml` — build, sign, TestFlight, plus restoring the gitignored config files from Codemagic secrets |

## Pending — needs a Mac or an Apple account

| Task | Needs | Notes |
|---|---|---|
| `pod install` + first compile | Mac / Codemagic | The project has never been built for iOS. Expect to fix small pod issues on the first run — that is normal, not a sign of a problem. |
| Signing & provisioning | Apple account | Certificates, App ID, profiles. `codemagic.yaml` fetches these automatically once App Store Connect is connected. |
| Push notifications | Apple account | Upload an APNs auth key to Firebase, enable the Push capability on the App ID, and add the `aps-environment` entitlement. **Deliberately not added yet** — the entitlement fails signing until the App ID actually has Push enabled. Android push is already live. |
| Home-screen widget target | Mac | `FitBoxRunWidget/FitBoxRunWidget.swift` exists but is not registered as a target in the Xcode project. Adding a target safely needs Xcode. |
| Live Activity / Dynamic Island | Mac | See `LIVE_ACTIVITY_NOTES.md`. iOS currently falls back to a standard ongoing notification. |
| Device testing | Mac + device | Background GPS, map rendering and permission prompts have never run on real iOS hardware. |
| TestFlight / App Store | Apple account | Build upload, privacy labels (fill them from `PrivacyInfo.xcprivacy` and the published policy), review submission. |

---

## ⚠ A second Maps API key is required for iOS

A Google Maps API key accepts **one** application restriction — *Android apps*
**or** *iOS apps*, never both. The existing key is restricted to the Android
package and its signing certificate, so **iOS will be rejected if it uses that
same key** ("This IP, site or mobile application is not authorized").

Create a second key before the first iOS build:

1. Google Cloud Console → **APIs & Services → Credentials → Create credentials → API key**
2. **Application restrictions → iOS apps** → add bundle ID `com.fitboxsports.app`
3. **API restrictions** → *Maps SDK for iOS*
4. Store it in Codemagic as `MAPS_API_KEY_IOS` (the Android one is `MAPS_API_KEY_ANDROID`)

For a local Mac build instead, put `MAPS_API_KEY=<ios key>` into
`ios/Flutter/Debug.xcconfig` and `Release.xcconfig` — both are gitignored paths
for this purpose in CI and must never hold a committed key.

## Files never committed (restored by CI from secrets)

```
ios/Runner/GoogleService-Info.plist   ← GOOGLE_SERVICE_INFO_PLIST
android/app/google-services.json      ← GOOGLE_SERVICES_JSON
android/local.properties              ← MAPS_API_KEY_ANDROID
ios/Flutter/*.xcconfig (key line)     ← MAPS_API_KEY_IOS
android/key.properties + .jks         ← CM_KEYSTORE and friends
```

## Rough estimate

With a Mac (or Codemagic) and an active Apple Developer account, **3–5 working
days** — mostly build configuration, push setup and device testing rather than
new development.
