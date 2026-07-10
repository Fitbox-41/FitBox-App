# FitBox App — Progress Log

A running development log. Newest entry on top. Weekly reports are added here each week.

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
