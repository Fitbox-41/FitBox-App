# iOS — the day the Apple Developer account exists

Written 24 September 2026, while waiting on the DUNS number (expected 25–30 Sep).
Everything here is blocked on the account and nothing else: the app already
compiles on Codemagic unsigned.

Do these in order. Each step says how to tell it worked.

---

## 0. Before the account arrives — prove the build still compiles

Run the **`ios-validate`** workflow in Codemagic now, on `main`.

It needs no Apple account and only the `firebase_and_maps` variable group, which
is already populated. Two dependencies were added on 24 September
(`flutter_timezone`, `timezone`) for the workout reminder, so the pods resolve
fresh — this is what proves they build on iOS.

**Worked when:** the build goes green and produces `Runner.app.zip` (~28 MB).
Neither new pod raises the deployment target (both declare iOS 11.0, the app is
on 15.0), so if `pod install` fails it is something else and worth reading
properly rather than bumping the floor.

---

## 1. Enrol, then connect App Store Connect to Codemagic

1. Enrol at developer.apple.com with the DUNS number — **as an organisation**,
   which is what the DUNS is for. Expect a day or two for Apple to verify.
2. App Store Connect → **Users and Access → Integrations → App Store Connect API**
   → generate a key. Download the `.p8` **once** — it cannot be downloaded again.
   Note the **Issuer ID** and **Key ID**.
3. Codemagic → **Teams → Integrations → App Store Connect** → connect it with
   those three values. Note the integration name you give it.

**Worked when:** the integration shows as connected in Codemagic.

---

## 2. Register the app identifier

App Store Connect → **Apps → +** → New App.

| Field | Value |
|---|---|
| Platform | iOS |
| Bundle ID | `com.fitboxsports.app` (must match `ios/Runner.xcodeproj`) |
| SKU | `fitbox-ios` |
| Name | FitBox |

Then copy the app's **numeric Apple ID** from its App Information page.

---

## 3. Turn on TestFlight publishing in `codemagic.yaml`

In the `ios-testflight` workflow:

1. Replace the placeholder — `APP_STORE_APPLE_ID: "0000000000"` — with the
   numeric ID from step 2.
2. Add the integration to the workflow's `environment:`
   ```yaml
   integrations:
     app_store_connect: <the integration name from step 1>
   ```
3. Uncomment the `publishing:` block at the bottom of that workflow.

**Why it is commented out and not just left in place:** `auth: integration`
refers to an integration configured in the Codemagic UI, and Codemagic rejects
the **whole file** if that reference can't be resolved — which would also stop
`ios-validate`, the one workflow that needs no Apple account. It was a real
failure on 13 August, not a hypothetical.

---

## 4. Push notifications (APNs)

Without this, iOS builds install and run but never receive a push — territory
attacks, season results and admin broadcasts all silently do nothing.

1. Apple Developer → **Certificates, Identifiers & Profiles → Keys** → new key
   with **Apple Push Notifications service (APNs)** enabled. Download the `.p8`.
2. Firebase Console → Project settings → **Cloud Messaging** → iOS app → upload
   that key with its Key ID and your Team ID.
3. In the app identifier, enable the **Push Notifications** capability.

**Worked when:** a test push from Firebase reaches a TestFlight build on a real
iPhone. The backend needs no change — `FIREBASE_SERVICE_ACCOUNT` is already set
and sends to whatever tokens are registered.

---

## 5. Run `ios-testflight`

**Worked when:** the build produces an `.ipa` and it appears in TestFlight.

Signing files are fetched automatically by `app-store-connect fetch-signing-files
--create`, so no certificates need creating by hand.

---

## Still to do after TestFlight works

These need a Mac or the Codemagic Mac instance and are **not** blocking a first
TestFlight build:

- **Home-screen widget.** The source is written and complete
  (`FitBoxRunWidget/FitBoxRunWidget.swift`, a proper WidgetKit `TimelineProvider`
  and `@main Widget`), but it has **zero references in `Runner.xcodeproj/project.pbxproj`**
  — an orphan file that is never compiled. That is why the `Runner.app` Codemagic
  produces has no `PlugIns` folder.

  **Decided: add the target by script, not in Xcode** — there is no Mac to hand.
  Use the **`xcodeproj` Ruby gem** in a Codemagic build step; it is already on the
  Mac images because CocoaPods depends on it. The step has to add the extension
  target, its build phases and the Swift file before `flutter build ipa` runs.

  Three things go with it:
  1. A second bundle id, `com.fitboxsports.app.FitBoxRunWidget`, registered in the
     Apple account.
  2. **A second `app-store-connect fetch-signing-files` call** in the
     `ios-testflight` workflow for that bundle id. The step currently fetches
     `$BUNDLE_ID` only, so signing would fail at the very end of an otherwise
     successful build.
  3. The App Group `group.com.fitboxsports.app` entitlement on **both** targets —
     the app side is already declared.

  **Do this after plain-app TestFlight is working, not alongside it.** If signing
  breaks while both are new, there are two candidates instead of one.

  Testing is covered: there is an iPhone 15 available once TestFlight is live.
- **Live Activity / Dynamic Island** — a native ActivityKit target, mirroring the
  Android ongoing run notification.

## Things that are already done — don't redo them

- Deployment target **iOS 15.0**, in the Podfile, the pod post-install hook and
  the Xcode project. Don't lower it: the Flutter pod itself requires it.
- Flutter **pinned to 3.44.1** in `codemagic.yaml`. A floating `stable` silently
  moved the deployment floor once and broke `pod install` with nothing in the
  repo having changed.
- `PrivacyInfo.xcprivacy` — Apple's required privacy manifest, declaring location,
  email, name, fitness and purchase data plus the required-reason APIs.
- `ITSAppUsesNonExemptEncryption = false`, so TestFlight stops asking on every
  upload.
- `permission_handler` trimmed in the Podfile to location, notifications and
  sensors only, so review isn't asked to explain permissions the app never uses.
- A **separate iOS Maps key** — a Google Maps key can be restricted to Android or
  iOS, not both. It exists and is in the `firebase_and_maps` group as
  `MAPS_API_KEY_IOS`.
