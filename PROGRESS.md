# FitBox App — Progress Log

A running development log. Newest entry on top. Weekly reports are added here each week.

---

## 29 July 2026 (later) — Phase 4: admin "FitBox App" section + FCM live + points UI

- **FCM push is live.** `FIREBASE_SERVICE_ACCOUNT` set on the app backend Vercel; `GET /api/push/status`
  → `{configured:true}`. Android delivery works now; iOS still needs an APNs key in Firebase.
- **Admin portal — new "FitBox App" section** (sidebar → `/app`), a tabbed page on the shared Atlas DB:
  - **Overview** — users, runs (+14-day chart), points economy (earned/redeemed/by-source/outstanding
    liability at ₹0.10), challenges, current-season territory.
  - **Users** — every app user with points, runs, distance, territory, push-enabled flag.
  - **Challenges** — full CRUD (create/edit/delete) → the app was showing an empty Challenges screen
    because nothing could create them; admins can now. Proxied to the app backend admin endpoints.
  - **Push** — composer (all users or a single user) wired to the live FCM sender; shows config status.
  - **Territory** — current season + reset date + season leaderboard.
  - Backend: `Backend/routes/app.js` (`/api/app/*`, `protect`) — analytics/users read the DB directly;
    challenges + push proxy to the app backend with the shared `X-Service-Key`.
  - **Admin backend Vercel env needed** for the Challenges/Push tabs: `APP_API_BASE=https://fit-box-app.vercel.app`
    and `WALLET_SERVICE_KEY` (same key as the app backend). Overview/Users/Territory work without them.
- **Website checkout aligned + points T&C.** `Cart.jsx` still used the old ₹2/point with **no cap** while
  the backend enforced ₹0.10 + 50% — fixed (shows point value, 50% rule, discount). The server cap now
  computes on the pre-discount order value so client preview == server clamp. Added a **"FitBox Points &
  Rewards"** clause to the website Terms page (no cash value, ₹0.10, 50% limit, earn/expiry/misuse/refund).
- **Verified.** App backend `push/status` live; admin frontend + website frontend both build clean;
  all three repos pushed to `main` (app, admin, website Vercel deploys triggered). Admin `/api/app`
  live-check pending the admin backend URL + an admin login.

---

## 29 July 2026 — Phase 3: seasons, true background run, FCM push (v1.16.0 → v1.17.0+39)

Follows Phase 1 (points economy: 1pt = ₹0.10, 50% redeem cap, in-app + website T&C) and Phase 2
(Challenges: admin-created steps/distance goals with a first-N reward cap; app screen + backend).

- **Weekly territory seasons (backend + app).** Territory is now scoped to an ISO week (e.g.
  `2026-W31`); the shared map and leaderboard count **only the current season**, so everyone's turf
  **auto-resets every Monday 00:00 UTC** (past weeks are kept as history). `Territory` unique index
  moved to `{userId, season}`; `GET /api/territories` returns `season` + `seasonEndsAt`. The app shows
  a **"SEASON · RESETS IN 2D 14H"** countdown on the territory card.
- **True background run.** The GPS stream runs under a **location foreground service** (Android, via
  geolocator's `ForegroundNotificationConfig`) so the timer, steps and route keep recording when the
  app is backgrounded or the screen is off — the run no longer freezes. iOS opts into background
  location (`UIBackgroundModes: location` + `AppleSettings`). Added `FOREGROUND_SERVICE` /
  `_LOCATION` / `WAKE_LOCK` perms and a runtime notifications request. On Android the FGS notification
  is the run notification (the live-stats local notification is now iOS-only, so there's only one).
- **Push notifications (FCM).** `firebase_core` + `firebase_messaging`: Firebase initialised at
  startup, device token registered per signed-in user, foreground messages surfaced locally, background
  handler wired. Backend: `firebase-admin` sender (`fcm.js`), `/api/push/register` + `/unregister`
  (auth) and a service-key `/api/push/send` (broadcast **or** targeted — for the admin push composer).
  **Territory capture now pushes** "under attack / territory lost" to contested users.
  - **Live sending needs `FIREBASE_SERVICE_ACCOUNT`** (the Firebase Admin JSON) set on the app
    backend's Vercel project. Until then `/send` returns 503 but token registration already works.
    iOS delivery additionally needs an APNs key uploaded to Firebase + push capability (Codemagic).
- **Verified.** `flutter analyze` clean; release APK built → `APKs/FitBox_v1.17.0_2026-07-29.apk`
  (72 MB). Backend deployed to `main` (Vercel): `/health` ok, `/api/territories` 401,
  `/api/push/register` 401, `/api/push/send` 403 — all as designed. On-device install pending a
  connected phone (none on adb this session).
- **Next — Phase 4 (admin portal).** New sidebar "App" section: App Analytics, App Users, Challenges
  CRUD, Territory/seasons controls, Points & Wallet + T&C editor, Push composer (uses `/api/push/send`).
  Plus website checkout UI for the 50% cap / ₹0.10 and the points T&C on the website T&C page.

---

## 23 July 2026 (later) — Guest mode, Maps cost report, login 500 fix (v1.9.2 → v1.10.x)

- **Guest mode (Phase 2 done):** "Continue as guest" on the landing → browse the app
  without an account. `guestModeProvider` gates account actions (auto-cleared on sign-in via the
  router). Wallet shows a sign-in `GuestGate`; Profile shows a "browsing as a guest" card instead of
  change-password / log out. Browsable tabs (Leaderboard/Goals/Settings/Notifications) stay open.
- **Auth transition polish:** landing ↔ Sign In / Create Account now **cross-fade** (opaque
  backgrounds so the whole screen blends, no snap); removed live `BackdropFilter` blurs app-wide
  (invisible over the gradient, expensive) — fixed the "loading lag"; `RepaintBoundary` on the carousel.
  Sign In / Create Account / Reset compacted to fit without scrolling; app-wide font trim.
- **Google Maps India cost report:** `docs/FitBox_Google_Maps_Cost_Report_India.pdf` (gitignored).
  **Headline: displaying maps in the mobile apps = ₹0, unlimited** (Maps SDK Android/iOS "Mobile Native
  Dynamic Maps" is free). Cost only from billed server APIs (Directions/Geocoding/Places) which FitBox
  avoids (GPS in-app). Mentor's gate before Maps build.
- **Login "Server Error" fixed (backend):** `loginUser` in the **website** `authController.js` called
  `bcrypt.compare(pw, user.password)` without checking `user.password` — for Google (passwordless)
  accounts that threw → **500** on manual sign-in (broke `glasgotra578@gmail.com` on app + web). Now
  returns a clear **401** ("This account uses Google sign-in…"). Pushed to `main` (Vercel redeployed),
  verified live. No app change needed (the app shows the server message). Both backends confirmed live.
- **Next (new chat):** Google Maps integration — wire keys into Android + iOS, replace `MapPlaceholder`
  with a real map + live GPS route on Territory / Record Run / Run Summary.

---

## 23 July 2026 — Weekly report: interactive redesign + design system + perf (v1.3.0 → v1.9.1)

**Design system.** Installed the **ui-ux-pro-max** skill (global, all projects) and generated a
persisted system at `design-system/fitbox/MASTER.md` with a locked brand override (FitBox = logo-red
+ Oswald; the engine's generic orange/Barlow is ignored). This drives the redesign.

**Auth + onboarding (Phase 2).**
- New **auth landing** (`/login`): full-bleed hero photo carousel (~62–66%) that cross-fades into a
  theme-aware sheet — **Sign In / Create Account** (Google/Apple live on the Sign In & Create Account
  forms). Matches the mockup the mentor/user signed off as the quality bar.
- New **3-step onboarding**: Welcome → Choose Theme (applies live) → Permissions (motion +
  notifications), each with a generated hero image (`assets/hero/onboard1–3.png`).
- **Sign In / Sign Up / Reset** rebuilt to fit without scrolling; forms use GlowButton + themed inputs.

**Full in-app redesign to the login bar.** Every screen upgraded with a shared motion language:
Home (count-up stat ring + tiles), Record Run (animated 3-2-1 countdown, live pulse, haptic controls),
Wallet (hero balance count-up + glass ledger + skeleton loader), Activity (glass run cards + "This week"
chart, relocated from Home) + Run Summary, Leaderboard (medal podium) + Goals (progress rings),
Profile + Settings (grouped glass rows; theme control now only in Settings), Territory + Notifications.
Added **iOS-style route transitions** and **reduced-motion** support + accessibility labels
(ui-ux-pro-max pre-delivery checklist).

**Performance.** Diagnosed app-wide "loading lag" as excessive **`BackdropFilter` blur** (one saveLayer
per glass card/nav/social button) — invisible over the smooth-gradient background but very costly.
Removed all live blurs (kept the frosted look via more-opaque fills); capped hero-image decode
(`cacheWidth`); `RepaintBoundary` on the carousel; and gave auth screens opaque backgrounds so the
landing→auth **cross-fade blends cleanly** with no snap/jerk.

**Backend.** Re-verified both Vercel backends are **live**: website auth (`…website-efns…`) and app
(`fit-box-app`) — protected endpoints return 401, i.e. up and enforcing auth. Earlier this window the
**wallet data model moved onto `users.walletBalance`** across both backends (legacy `wallets`
collection dropped; balances reconciled), pushed directly to `main`.

**Status:** analyze clean, widget test passing, web + APK built every step; web redeployed to
`fitboxsports-8d1c0.web.app`, APKs installed on device. Shipped versions 1.3.0 → **1.9.1+22**.

**Pending / next:** guest mode ("Continue as guest" + gated account actions) to close Phase 2 → Google
Maps **India cost report (PDF)** → Maps integration → live run activity (Android notif + iOS Dynamic
Island) → Dare feature.

---

## 18 July 2026 — Full "Aerostride" redesign complete (v1.2.0)

- Redesigned the **entire app** to the Stitch-derived Aerostride design (Apple-grade glassmorphism,
  charcoal + red, kinetic italic), from the `design/` reference folder.
- **Fonts locked:** Android → Inter (google_fonts), iOS → SF Pro (system), via `platformFont()`.
- **Every screen done:** splash, onboarding (new, first-run gated), login, signup, reset, home,
  territory (new), activity/history, record run + run summary (new), wallet, leaderboard (new),
  goals (new), notifications (new), settings (new), profile.
- **5-tab floating glass nav** (Home / Territory / Activity / Wallet / Profile) + full routing:
  Start-a-run + home-screen widget → record run; run cards → summary; profile → leaderboard/goals/
  settings/notifications.
- Real FitBox logo blended per theme (no Stitch logo, no white chip). Google button uses the real
  multi-colour "G"; added an Apple sign-in button (coming soon).
- **Home-screen widget** "Start a run": Android live; iOS WidgetKit scaffolded (one-time Xcode target).
- Map-dependent screens (territory / record / summary) use a stylised map placeholder until the Google
  Maps key arrives.
- Verified: analyze clean, tests pass, web + APK build; web redeployed; APK installed on device.
- Versioned APKs now live in `APKs/` as `FitBox_v<version>_<date>.apk` (gitignored).

---

## 14 July 2026 (EOD) — Wallet end-to-end, secured + verified live

- **Confirmed the app backend is wired to the live shared MongoDB Atlas** and verifies the website's
  login tokens (same `JWT_SECRET`) — the wallet **read** path is live end-to-end.
- **Fixed a security hole**: `POST /api/wallet/credit` used to let any logged-in user credit themselves
  unlimited points. Wallet mutations (credit + redeem) are now **server-to-server only**, gated by a
  shared `WALLET_SERVICE_KEY` (fail-closed when unset). End users can only *read* their own wallet.
- **Built `POST /api/wallet/redeem`** (debit) — atomic, idempotent per order, balance-checked (never goes
  negative). This is what the website checkout will call.
- **Verified the whole ledger live**: credit 100 → 100; redeem 30 → 70; repeat same key → "Already
  processed" (70, no double-debit); redeem over balance → "Insufficient balance". Idempotency + atomicity
  proven against the real DB. _(Left a sentinel test wallet `userId 000000000000000000000001` — safe to delete.)_
- **Wrote `backend/HANDOFF_WALLET.md`** — full schema + endpoint contracts + redeem flow + tests for
  Diwakar to build the website checkout redeem (time-critical: he leaves end July).
- `WALLET_SERVICE_KEY` set on the app + website backends and redeployed (git auto-deploy now working).
- App polish: wallet balance now animates a count-up (matches the dashboard step ring).
- **Delivered for testing:** fresh release APK at `Desktop\FitBox-test.apk`; web redeployed at
  https://fitboxsports-8d1c0.web.app. Verified: analyze clean, tests passing, web + APK build.
- **Open (needs others):** owner to confirm point→currency conversion rate + cap; Diwakar to build the
  website checkout redeem from the handoff doc.

---

## 14 July 2026 — Health Connect + HealthKit (accurate stats + history)

- **Accurate fitness data** now comes from the platform health store: **Health Connect** on Android and
  **HealthKit** on iOS, via the `health` package. We read real steps, active calories and distance, plus a
  **7-day history** for the weekly chart (previously sample data).
- Graceful fallback chain: health store → device pedometer (step sensor) → sample data on web.
- Web stays safe: the health plugin is `dart:io`-only, so it's isolated behind conditional imports
  (`health_source.dart` + `_io`/`_stub`) and never touches the web build.
- Native wiring done on **both** platforms in one change (per the all-platforms rule): Android health
  read-permissions + rationale intent-filters + Health Connect package query + `FlutterFragmentActivity`
  + compileSdk 36 / minSdk 26; iOS HealthKit entitlement + Info.plist usage strings.
- Verified: analyze clean, test passing, web build + APK build; web redeployed.
- **Still to do on device:** grant Health Connect permission on an Android phone and confirm the numbers;
  iOS HealthKit capability needs enabling in the Codemagic/Xcode build (entitlement file is in place).

---

## 11 July 2026 — Real fitness stats + Stitch prompt

- **Real step tracking** on mobile via the device pedometer: today's steps (with a persisted daily
  baseline), and derived distance, calories and active minutes. Android asks for Activity Recognition;
  iOS uses a motion usage string. Web has no sensor, so it falls back to sample data.
- Dashboard now streams live stats (`fitnessStatsProvider` is a StreamProvider). Weekly-history chart
  still sample — accurate history needs Health Connect / HealthKit (a later upgrade).
- Wrote `docs/STITCH_PROMPT.md` — a reusable style block + per-screen prompts covering the full app
  (auth, dashboard, run tracking, run summary, activity, territory map, leaderboard, wallet, goals,
  profile, settings, notifications) for generating designs in Google Stitch.
- Verified: analyze clean, test passing, web + APK build; redeployed.

---

## 11 July 2026 — Auth glass polish + motion

- **Login** form now sits in a frosted glass card with the logo badge above it; **sign-up** gained the
  logo badge in its header too. All auth screens (login/signup/reset/change-password) are now glassy.
- **Hero logo transition**: the logo badge animates smoothly between splash → login → sign-up.
- **Dashboard step ring** now animates a count-up (ring fills + step number/percent count from 0).
- Verified: analyze clean, test passing, web + APK build; redeployed.

---

## 11 July 2026 — Light/dark theming, animations, logo fix

- **Light + dark glass themes**, following the **system theme by default**, with a **System / Light / Dark
  toggle** in Profile → Appearance (persisted). All screens use theme-aware colours (adapt to both).
- **Entrance animations** (staggered fade + slide) on dashboard, wallet, activity and profile via
  `flutter_animate`.
- **Logo fix:** the mark now sits on a crisp white rounded "badge" (`LogoBadge`) so it reads perfectly on
  any theme — no more recolour artifacts on dark.
- One codebase → same UI/theme on Android + iOS + Web; every change applies to all. Analyze clean, test
  passing, web + APK build. Redeployed.

---

## 11 July 2026 — Glassmorphism redesign + sign-in spinner

- **Premium dark "glass" redesign** (Apple-style, on the FitBox charcoal/red brand): app-wide deep
  gradient background with a soft red glow; frosted-glass cards (`GlassCard`) across the dashboard,
  wallet, activity and profile; a frosted bottom nav bar; red accents and white text.
- Dashboard now greets the user by name; wallet balance is a glowing red gradient card.
- **Google sign-in loading overlay** on web while the account is being verified (the earlier delay).
- All platforms (Android + iOS + Web) from one codebase; analyze clean, widget test passing, web + APK
  build. Redeployed to https://fitboxsports-8d1c0.web.app.
- This is a first cohesive glass pass; will refine (and can swap in Stitch designs later).

---

## 11 July 2026 — Web/UI fixes round 2

- **Login logo was oversized** (it sat in a stretch column so `width` was ignored → filled the screen and
  pushed content off-screen, causing the scroll). Fixed by centering it at a fixed size. This also makes the
  page fit without scrolling on mobile and look right on PC.
- **Dark-theme logo:** added a light logo variant so the mark stays visible on dark backgrounds.
- **Web Google sign-in attempted but reverted:** the GIS init hung the web app on the splash screen on load
  (the hosting domain likely isn't in the OAuth client's authorized JS origins). Deferred again; email login
  works on web. Added a **session-restore timeout** so the app can never get stuck on splash.
- Web redeployed and verified rendering the login screen.

---

## 11 July 2026 (late) — Web/UI fixes

- **Logout fixed** — it silently failed on web (Google sign-out threw before the state updated); now the
  auth state clears first (router redirects immediately), Google sign-out is best-effort.
- **Responsive:** removed the desktop "phone frame". PCs get a **side navigation rail** + centred, width-
  capped content; phones keep the bottom bar. Auth forms are width-capped so they don't stretch on desktop.
- **Mobile web now fits** — added the missing HTML **viewport meta** (mobile was laying out at desktop width
  and overflowing/scrolling).
- **Logo** now has a transparent background (looks "submerged", not a pasted white block); used on splash/login.
- **Web branding:** favicon + PWA icons set to the FitBox logo; title/manifest set to "FitBox".
- Deferred: **Google sign-in on web** (v7 web needs a rendered-button flow + adding the hosting domain to the
  OAuth client's authorized origins) — next; email login works on web meanwhile.
- Redeployed: https://fitboxsports-8d1c0.web.app  ·  analyze clean, web build + deploy OK.

---

## 11 July 2026 (pm) — Web app live (owner testing)

- **Added Flutter Web** (same codebase, same repo) so the owner can test in iPhone Safari / any browser
  before iOS TestFlight is ready. Android/iOS untouched — all three platforms now build from one codebase.
- **Responsive:** phones/mobile-web use full width; larger screens show the app centred in a phone-sized
  frame. Google button hidden on web (email/password/OTP all work on web).
- **Deployed live on Firebase Hosting:** https://fitboxsports-8d1c0.web.app  (redeploy:
  `flutter build web --release && firebase deploy --only hosting`).
- From now on: build/verify **Android + iOS + Web together** each change.
- Verified: analyze clean, web build + deploy succeed, live login screen renders.

---

## 11 July 2026 — Password management

- **Set / change password** (Profile → "Set / change password"): new password + confirm, with an
  optional current-password field (Google users who never set one can leave it blank). The current
  password is verified client-side via the login endpoint (no website change; login sends no OTP).
- **Forgot password** (login → "Forgot password?"): email → 6-digit OTP → set a new password; the user
  is signed in afterwards. Uses `forgot-password-otp` + `verify-reset-otp` + `password` endpoints.
- No website changes required. Verified: analyze clean, test passing, APK built + installed.

---

## 10 July 2026 (eve) — Google sign-in

- **Google sign-in implemented** (`google_sign_in` v7): "Continue with Google" on login and sign-up.
  Direct flow — Google verifies the email, so no OTP and no password; new users are created via the
  website's `/api/auth/google` (no website changes). JWT stored as usual.
- **Android:** debug SHA-1 registered in Firebase; new `google-services.json` in place (gitignored).
- **iOS config prepared** (for the later Codemagic build, not testable on Windows): `GoogleService-Info.plist`
  fetched (gitignored) and the reversed-client-ID URL scheme added to `Info.plist`.
- Verified: analyze clean, widget test passing, **debug APK built and installed on the phone** for
  live Google sign-in testing.
- Note: email-OTP sign-up is kept (Google is pre-verified). Apple sign-in is a future add (needs the
  Apple Developer account).

---

## 10 July 2026 (pm) — Live backend, brand theme, Firebase setup

- **App wired to the live backend** (`fit-box-app.vercel.app`): wallet balance/ledger and run history
  now load live from the shared MongoDB via authenticated API calls. Daily fitness stats (steps/calories)
  stay mock until device-sensor integration.
- **Recolored to the real brand** — charcoal + red (from the logo), replacing the placeholder green/orange.
- **Firebase configured for Google sign-in**: registered Android + iOS apps in `fitboxsports-8d1c0`,
  fetched config (`google-services.json`, `firebase_options.dart` — all gitignored, kept out of the public
  repo). Google flow will be **direct sign-up + optional profile** (no website changes). Remaining before it
  works: register the app's debug SHA-1 in Firebase, then wire the button and test on a device.
- Verified: `flutter analyze` clean, widget test passing, APK builds.

---

## 10 July 2026 — Authentication + login/signup

- **Live database connected & verified.** App backend `.env` configured with the shared MongoDB
  Atlas URI (own DB user) and the website's `JWT_SECRET`; test connection succeeds against the shared
  `test` database (sees `users`, `products`, `orders`, `admin_users`, …). Env files for all repos are
  gitignored (root `.gitignore` added for the website/admin `.env`).
- **Auth built (real, against the live website API).** Email/password **login** and a two-step
  **sign-up** (email → 6-digit OTP → create account) wired to the website's `/api/auth` endpoints;
  JWT stored in secure storage; auto-restore of the session on app start; **logout** on the profile
  screen. Riverpod auth state + go_router redirects (splash → login → app shell).
- Uses the website's shared login so an app account is the same customer as on the website.
- Verified: `flutter analyze` clean, widget test passing, live login endpoint returns the expected
  401/JSON, debug APK builds. (Wallet/activity still on mock until the app backend is deployed.)

---

## 9 July 2026 — App backend added + hardened

- **App backend built** (Node/Express, in `backend/`): wallet, runs and territory Mongoose models;
  JWT-verify middleware using the shared `JWT_SECRET`; an idempotent, transactional wallet `/credit`
  plus `GET /wallet`; and basic runs/territory routes. Geospatial models use GeoJSON + `2dsphere` indexes.
- **Hardened for deployment:**
  - Removed `node_modules` from version control (was committed by mistake) and fixed the ignore rule.
  - Made it cloud-ready (Vercel): the server is exported for serverless, database connections are reused,
    a health check works even if the DB is down, and a `vercel.json` was added.
  - Security fix: a run/territory can no longer be saved under another user's id via the request body.
  - Pinned exact database collection names so the app, website and admin all share the same wallet data
    (`wallets`, `wallet_transactions`) — coordinated with the website developer.
  - Aligned the database setting name with the website (`MONGO_URI`) and added a safe `.env.example`.
- Verified locally: server boots and the health endpoint responds; the Flutter app is unchanged.
- Progress report for the mentor generated (`docs/FitBox_App_Progress_Report.pdf`).

---

## Week 1 — commencing 6 July 2026

**Status:** foundation complete; architecture agreed; repos live. App frontend coding starts 7 July.

### Done
- **Project & repos set up.** App project connected to `Fitbox-41/FitBox-App` (`main`). Website and
  admin cloned fresh and set up on a `Gautam` working branch (PRs reviewed/merged by Diwakar).
- **Architecture decided and documented.** Single MongoDB Atlas shared across app/website/admin; a
  separate app backend (Node/Express on Vercel) that the app talks to over HTTPS; shared login (the
  website's JWT, keyed by the customer's Mongo `_id`); shared points wallet with an idempotent ledger.
  See `ARCHITECTURE.md`.
- **Scope confirmed.** The app is a full fitness app (steps, calories, distance, pace, activity history,
  goals/streaks) plus the territory-capture game and the rewards wallet.
- **Owner deliverables produced:** system architecture PDF and an access/keys-required PDF.
- **Frontend foundation built (Riverpod + go_router).** App shell with bottom navigation
  (Home / Activity / Wallet / Profile), FitBox theme, clean `lib/src` layout, and a mock data
  layer behind Riverpod `FutureProvider`s (so real loading/error states are exercised now and
  only the provider bodies change when the live backend arrives).
- **First screens working on mock data:** Home dashboard (steps ring, calories/distance/active
  minutes, weekly bar chart), Activity history (runs with distance/time/pace/calories), Wallet
  (points balance + transaction ledger). `flutter analyze` clean, widget test passing, debug APK
  built and installed on a physical Android device.

### Next (weeks 1–2)
- Login screen + auth flow against the website's existing endpoints.
- Wire the app to the live backend + shared database once the backend URL is available (~week 2)
  by swapping the mock providers for `dio` API calls.
- Begin GPS/run and map screens.

### Blocked on / needed
- MongoDB Atlas access, `JWT_SECRET`, Google Maps API keys (see the access/keys doc).
- Live backend URL — expected from the website side by week 2.

### Cross-system (July, with Diwakar — he leaves end of July)
- Lock the shared wallet schema; build wallet end-to-end (earn in app → same balance → redeem at
  website checkout); add app-data section(s) to the admin portal.
