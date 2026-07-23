# FitBox — Project Handoff (→ start Google Maps Integration)

> **How to use this doc:** paste/attach this file at the start of a new chat and say "continue FitBox — start
> Google Maps integration." It contains everything needed to pick up with zero prior context. Written 23 Jul 2026.

---

## 1. What FitBox is

A **Flutter fitness app** (internship project) with three pillars:
1. **GPS run tracking** — record runs (distance / pace / route).
2. **Territory-capture game** — claim map zones as you run.
3. **Shared points wallet** — earn points for activity, **spend at checkout on the FitBox e-commerce
   website** (a separate MERN app that shares the same MongoDB Atlas + user accounts).

iOS-first feel, premium/interactive. Brand = the **FitBox logo red** + **Oswald** typeface.

---

## 2. Repos, structure, git

Root: `C:\Users\Gautam Lasgotra\Music\Internship\FitBox\` — three sibling folders:

| Folder | What | Git | Deploy |
|---|---|---|---|
| **FitBox_App** | The Flutter app (+ its own Node/Express **app backend** in `backend/`) | tracked, **push to `main`** | APK to device; Flutter **web** → Firebase Hosting |
| **FitBox_Website** | MERN e-commerce site + **auth backend** (`Backend/`) | local branch `Gautam`, **deploys from `main`** — push `HEAD:main` | Vercel (auto) |
| **FitBox_Admin** | Admin panel | local branch `Gautam` | Vercel |

**Standing permission:** push directly to `main` for all repos (no more feature-branch review). For the
website/admin, local branch is `Gautam`; push with `git push origin HEAD:main`.

---

## 3. Backends & data (both LIVE, verified 23 Jul 2026)

- **Website/auth backend:** `https://fit-box-sports-website-efns.vercel.app` — auth (email+password, email-OTP
  register, Google), issues the JWT. Config in app: `lib/src/core/config/app_config.dart` → `websiteApiBase`.
- **App backend:** `https://fit-box-app.vercel.app` — wallet / runs / territory. `appApiBase` (overridable via
  `--dart-define=APP_API_BASE=`).
- **Shared MongoDB Atlas** — one DB. App backend **verifies the website's JWT** with the shared `JWT_SECRET`.
- Health check: protected routes return **401** = alive; bare `/api` 404 is expected.

### Auth reality (important)
- **Custom JWT** (30-day, signed `JWT_SECRET`), keyed by **Mongo `_id`** (payload `{ id }`). **NOT Firebase Auth.**
  Firebase is used for FCM push only. `protect` middleware: `FitBox_Website/Backend/MiddleWare/authMiddleware.js`.
- **Google accounts are passwordless** (`password` optional, `authProvider:'google'`). To sign in to a Google
  account with a password, the user must first set one via **Forgot password** (reset flow works for them).
- **Just fixed (23 Jul):** `loginUser` (`FitBox_Website/Backend/Controllers/authController.js`) used to call
  `bcrypt.compare(pw, user.password)` without a null-check → for Google accounts it threw → **500 "Server Error"**
  on manual sign-in (this broke `glasgotra578@gmail.com` on app + web). Now guards `user.password` → clean **401**
  with a helpful message; 400 on missing fields. Deployed to `main`, verified. **The app shows the server's
  `message` verbatim** (`messageFromError` in `lib/src/services/api_client.dart`), so no app change was needed.

### Wallet data model
- Balance lives on **`users.walletBalance`** (visible in the users collection). Ledger = **`wallet_transactions`**.
  The legacy `wallets` collection was dropped + reconciled. Wallet **mutations are service-to-service only**
  (gated by `WALLET_SERVICE_KEY`); end users can only read. Redeem is atomic + idempotent per order.

---

## 4. Design system & UI conventions

- **ui-ux-pro-max** skill is installed globally. Persisted system: `FitBox_App/design-system/fitbox/MASTER.md`
  (has a **locked brand override** at the top: use logo-red + Oswald, ignore the engine's generic orange/Barlow).
- **The login/auth landing is the quality bar** for every screen (full-bleed hero carousel that cross-fades into
  a theme-aware sheet). Every in-app screen was rebuilt to it.
- **Typography:** `lib/src/core/theme/app_typography.dart` — Oswald for display/titles/metrics/labels (both
  platforms); platform body (SF Pro iOS / Inter Android). Use `AppText.kinetic/data/labelCaps(context, size:)` or
  `AppTypography.heading/title/label/body/caption/button/screenTitle(size:,color:)`. Note: `displayLarge`/`bodySmall`
  take NO size arg. App-wide sizes were trimmed — keep headings ~20-28.
- **Surfaces/widgets:** `FitBoxColors` (logoRed #E31E24, red #D8474D, redDark, credit #19A463, debit #E5484D,
  bgTopDark/bgBottomDark). `GlassCard`, `GlowButton` (red, radius 6), `StatTile`, `SectionHeader`, `CardLabel`,
  `LogoBadge`, social buttons.
- **Motion primitives** (`lib/src/presentation/widgets/motion.dart`): `AppMotion.expoOut`, `.revealStagger()`,
  `.reveal()`, `CountUpText` — all respect **reduced-motion**. Shimmer loaders in `widgets/shimmer.dart`.
- **PERF — do NOT reintroduce `BackdropFilter`/live blur** in cards or lists. The app background is a smooth
  gradient, so blur is invisible but very expensive; we removed all live blurs (GlassCard/nav/social buttons use a
  more-opaque translucent fill instead). Reintroducing blur brings back the app-wide lag.
- **Route transitions:** pushed in-app routes use iOS `CupertinoPage` (slide + swipe-back); **auth routes
  cross-fade** (`_fade` in `app_router.dart`) with opaque backgrounds so the blend is clean.
- **Guest mode:** `guestModeProvider` (in `auth_controller.dart`). "Continue as guest" on the landing → browse the
  app; account actions gated (`GuestGate` widget). Auto-cleared on sign-in (router listener).

---

## 5. Current app state (v1.10.1+25)

Every screen is redesigned + interactive. Routing in `lib/src/core/router/app_router.dart` (StatefulShellRoute:
Home / Territory / Activity / Wallet / Profile; pushed: record-run, run-summary, leaderboard, goals, notifications,
settings, change-password, signin/signup/reset).

- **Onboarding** (first-run only): Welcome → Choose Theme (live) → Permissions. Hero images `assets/hero/onboard1-3.png`.
- **Auth:** landing (`/login`) + Sign In (`/signin`) + Create Account (`/signup`, has Google/Apple) + Reset. Hero
  images `assets/hero/login1-4.png`.
- **Home:** count-up steps ring + stat tiles + "Start a run" (weekly chart was moved to Activity).
- **Record Run:** animated 3-2-1 countdown, live pulse, haptic controls, `MapPlaceholder` background.
- **Wallet / Activity / Run Summary / Leaderboard / Goals / Profile / Settings / Territory / Notifications:** all
  redesigned; map screens use `lib/src/presentation/widgets/map_placeholder.dart` (a styled placeholder).
- **Fitness data policy:** record ONLY in-app runs; **no** Apple Health / Health Connect sync.

### Build / test / deploy (exact commands)
```bash
cd "C:/Users/Gautam Lasgotra/Music/Internship/FitBox/FitBox_App"
flutter analyze                       # must be clean
flutter test                          # widget test asserts the auth landing
# bump pubspec version, then:
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk "APKs/FitBox_v<ver>_<date>.apk"   # APKs/ gitignored
adb -s HQXKO7LN55EQCA4D install -r "APKs/FitBox_v<ver>_<date>.apk"                 # device id
flutter build web --release && firebase deploy --only hosting --project fitboxsports-8d1c0
```
- Device: **HQXKO7LN55EQCA4D**. Package: **com.fitboxsports.app**. Web: **https://fitboxsports-8d1c0.web.app**.
- Device **blocks `adb pm clear`** — to re-trigger first-run onboarding, `adb uninstall` then `install` (loses session).
- LF→CRLF git warnings are harmless. Commit trailer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

## 6. ▶ NEXT TASK — Google Maps Integration (start here)

**Unblocked:** the user has **Google Maps API keys for iOS and Android**, and the **cost report is done** —
`docs/FitBox_Google_Maps_Cost_Report_India.pdf`. **Headline: displaying maps in the mobile apps costs ₹0 /
unlimited** (Maps SDK Android/iOS "Mobile Native Dynamic Maps" is free). Cost only from billed server APIs
(Directions/Geocoding/Places) which we **avoid** — route comes from the device GPS.

### Scope
1. **Add deps:** `google_maps_flutter`, plus a location package (`geolocator` recommended) for the live GPS route.
2. **Wire keys (native config, both platforms together):**
   - Android: `android/app/src/main/AndroidManifest.xml` → `<meta-data android:name="com.google.android.geo.API_KEY" .../>`
     (keep the key out of git — use a gitignored `secrets.properties` / `--dart-define` / local.properties pattern).
   - iOS: `ios/Runner/AppDelegate.swift` `GMSServices.provideAPIKey(...)` + Info.plist location usage strings.
     (Build as far as Windows allows; the Xcode/signing steps happen on **Codemagic** per the standing iOS policy.)
3. **Replace `MapPlaceholder`** (`lib/src/presentation/widgets/map_placeholder.dart`) with a real map on
   **Territory**, **Record Run**, and **Run Summary** — keep the map layer **abstracted** behind a small widget so a
   later swap to Mapbox (for premium dark styling) stays easy.
4. **Live GPS run:** stream location during a run → draw a **polyline**, compute **real distance/pace** (replaces the
   step-derived distance for outdoor runs; still in-app only, no Health sync). Existing run session:
   `lib/src/data/run_session.dart`; recorded runs `lib/src/data/recorded_runs.dart`.
5. **Territory game:** capture zones as the user runs (define the zone model + capture rule; render claimed zones on
   the map). This is the big gameplay payoff.
6. **Safeguards to set in Google Cloud console:** enable **only the Maps SDKs**, **restrict the API keys** (Android
   package + SHA-1; iOS bundle id), and set a **low budget alert** — belt-and-suspenders since usage is ₹0.
7. **Permissions:** location permission is already messaged in onboarding as "asked later"; request it when the user
   first starts a map/territory run (`permission_handler` is already a dependency).

Google's public client id (not secret) already in `app_config.dart`: `googleServerClientId` (for Google **sign-in**,
unrelated to Maps). The **Maps** API keys are the ones the user holds — get them into native config, not committed.

### After Maps (later roadmap)
- **Live run activity:** Android foreground-service notification (publish-ready) + iOS Dynamic Island / Live Activity
  (ActivityKit — built to the Codemagic boundary; App Group `group.com.fitboxsports.app` already set).
- **Dare feature:** challenge cards → accept → run (design mock `design/custom/dare.png`).

---

## 7. Memory pointers (auto-loaded each session)

`~/.claude/projects/.../memory/` — index `MEMORY.md`. Key entries: project-structure, auth-reality (updated with the
login fix), architecture-decisions, cross-repo-workflow, current-sprint, weekly-reports, **gmaps-deferred** (updated:
keys in hand + cost report done → integrate next), design-system, ui-standard, designsystem-doc, fitness-data-policy,
web-cors-login.

---

*Prepared 23 Jul 2026 · app at v1.10.1+25 · login Server-Error fix live · next: Google Maps integration.*
