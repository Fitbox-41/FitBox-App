# FitBox App — Progress Log

A running development log. Newest entry on top. Weekly reports are added here each week.

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
