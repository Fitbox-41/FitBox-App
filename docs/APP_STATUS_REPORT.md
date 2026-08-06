# FitBox App — Status Report

_As of 14 July 2026._ Honest, feature-by-feature status of the Flutter app (Android + iOS + Web).
"Live" = talking to the real backend / real device data, not mock.

> **⚠ Historical snapshot — do not read as current state.** Two things below have
> since changed: **Health Connect / HealthKit was removed** (activity now comes
> only from runs recorded in the app), and runs/territory/points work differently
> as of v1.18.0. For current state see `../PROGRESS.md` (newest entry on top),
> `../README.md` and `../ARCHITECTURE.md`.

**Live web build (test in any browser):** https://fitboxsports-8d1c0.web.app

---

## Overall: the app is roughly **~55–60% complete**

The **foundation, design, auth, and fitness tracking are done and live.** What remains is mostly the
**map / GPS / territory game** (waiting on the Google Maps API key) and the **shared wallet end-to-end
proof** (needs Diwakar's website-side redeem). Those are the big remaining chunks.

---

## ✅ Done (built + verified)

### Foundation & platform (100%)
- Flutter app with Riverpod state management, go_router navigation, secure token storage.
- **All 3 platforms build from one codebase** — Android (APK), Web (deployed live), iOS (Codemagic config ready).
- Same UI/theme everywhere (all future changes land on all platforms together).

### Design / UI (100% for current screens)
- **Apple-style glassmorphism** across every screen, on the FitBox charcoal + red brand.
- **Light / Dark / System theme** with a toggle (follows the phone's system theme by default).
- Responsive layout — proper on **PC and mobile web** (and native app).
- Entrance animations, animated step-ring count-up, hero logo transition.

### Authentication (100%, live)
- Email + password **login** — live against the website backend (shared customer account).
- **Sign-up with email OTP** — live.
- **Google sign-in** — live on both mobile and web.
- **Password management** — set password (for Google users), change password, reset via 6-digit OTP.
- Session restore on launch + secure JWT storage.

### Fitness tracking (100% code; needs on-device confirmation)
- Real **steps, calories, distance** from **Health Connect (Android)** and **HealthKit (iOS)**.
- **7-day history** for the weekly chart.
- Fallback chain: health store → device step sensor → sample data (web).
- Dashboard streams live stats.
- _Pending: grant permission on a real Android phone and confirm the numbers._

---

## 🟡 Partly done

### Shared points wallet (~65%)
- **App side (frontend): done** — wallet screen reads balance + transaction history live from the app backend.
- **Live shared DB: confirmed** — the app backend is deployed and verifiably connected to the shared
  MongoDB Atlas and verifies the website's login tokens (same `JWT_SECRET`). The wallet **read** path is
  wired end-to-end.
- **App backend: built + hardened** — atomic, idempotent ledger; a new **redeem (debit)** endpoint with a
  balance check; and wallet mutations are now **server-to-server only** (fixed a hole where any logged-in
  user could credit themselves unlimited points).
- **Handoff spec written** for Diwakar (`backend/HANDOFF_WALLET.md`) — schema + endpoint contracts +
  redeem flow + tests, so the website checkout redeem can be built while he's here (leaves end July).
- **Verified live**: against the real DB — credit → balance, redeem → balance, repeat is idempotent (no
  double-debit), and over-balance redeem is refused. The wallet plumbing is proven.
- **Pending:** (1) website-side **redeem at checkout** (Diwakar, from the handoff doc); (2) owner to
  confirm the **point→currency conversion**; then the full "one balance across app + website" demo.

### Activity / runs (~30%)
- **Activity screen: done** — reads the user's runs from the backend and lists them.
- **Pending:** actually **recording a run** (GPS) and the map — see below.

---

## ⛔ Not started yet (next phases)

### GPS run tracking + Maps — **BLOCKED on Google Maps API key**
- Recording a live run (route, pace, distance on a map) needs the **Google Maps API key**, which isn't
  available yet. **Deferred** — we'll build the rest of the app first and add maps once the key arrives.

### Territory capture game (Aug+)
- Claim / capture territory on the map (the Strava-style core game). Depends on maps + run tracking above.

### Leaderboard / weekly winner (Aug+)
### Push notifications — FCM (Aug+)
### iOS TestFlight publish (needs Apple credentials + HealthKit capability wired in Codemagic)

---

## What you can test right now
- **Web:** https://fitboxsports-8d1c0.web.app (works on iPhone Safari + PC).
- **Android:** the test APK (see the message with this report) — install it, sign in, and check the
  dashboard fitness stats (grant the Health Connect permission when asked).
