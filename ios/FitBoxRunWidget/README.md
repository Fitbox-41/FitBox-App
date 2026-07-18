# iOS home-screen widget — Xcode wiring (one-time)

The widget UI (`FitBoxRunWidget.swift`), the Flutter deep-link handling, the `fitbox` URL scheme, the
**App Group entitlement** (`group.com.fitboxsports.app` in `Runner.entitlements`), and the Dart
`HomeWidget.setAppGroupId(...)` call are all done. The only remaining step is adding the Widget Extension
**target** in Xcode and ticking the same App Group on it — this can't be done from Windows/CI without
Xcode, so do it once on a Mac (or a Codemagic build step) and it's set for good.

The Android widget is already fully wired and needs none of this.

## Steps (in Xcode, on the `ios/Runner.xcworkspace`)
1. **File → New → Target… → Widget Extension.** Name it **`FitBoxRunWidget`**. Uncheck "Include Live
   Activity" and "Include Configuration Intent" (this is a static widget).
2. When it creates a default `FitBoxRunWidget.swift`, **replace its contents** with our
   `ios/FitBoxRunWidget/FitBoxRunWidget.swift` (or delete the generated file and add ours to the target).
3. **App Group** (lets the app and widget share data — required by `home_widget`):
   - Select the **Runner** target → Signing & Capabilities → **+ Capability → App Groups** → add
     `group.com.fitboxsports.app`.
   - Do the same for the **FitBoxRunWidget** target (same group id).
4. In Dart, set the group id once at startup (already safe to add):
   `HomeWidget.setAppGroupId('group.com.fitboxsports.app');`
5. Deep link is already registered: the app's `Info.plist` declares the `fitbox` URL scheme, and
   `app.dart` listens for `fitbox://start-run` and routes into the run flow.
6. Build to a device. The widget appears in the widget gallery as **"FitBox — Start a run"**; tapping it
   opens the app into the run flow.

## Codemagic
Add the target + App Group in the project once and commit the `.pbxproj` changes; Codemagic then builds
it like any other target (ensure the extension's bundle id and provisioning profile are configured).
