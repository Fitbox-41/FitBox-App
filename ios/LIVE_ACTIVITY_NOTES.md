# iOS — Live Run Activity / Dynamic Island (Codemagic / Xcode step)

The Android live-run notification ships in Dart (`lib/src/services/run_notifier.dart`,
driven by `run_session.dart`). On iOS that same code shows a **standard notification**.
The **Dynamic Island / Lock-Screen Live Activity** is a native **ActivityKit** widget that
can only be built with Xcode, so it's deferred to the Codemagic/Mac build. When on a Mac:

1. Add a **Widget Extension** target (e.g. `RunLiveActivity`) with an `ActivityConfiguration`.
2. Define an `ActivityAttributes` with the live fields: `elapsed`, `distanceKm`, `pace`.
3. `Info.plist`: add `NSSupportsLiveActivities = YES` (Runner target).
4. Bridge from Flutter: start/update/end the Activity from `run_session.dart` via a
   `MethodChannel` (or the `live_activities` pub package) on start / each tick / finish.
   The App Group `group.com.fitboxsports.app` is already configured (shared with the
   home-screen widget) for passing state.
5. Design the island/lock-screen views to match the brand (Oswald, logo-red, route dot).

Until then, iOS users get the ongoing local notification via flutter_local_notifications.
