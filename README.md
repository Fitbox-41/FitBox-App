# FitBox App

The FitBox fitness mobile app (Flutter) — GPS run tracking, a contested
"territory" land-grab game, activity challenges, and a rewards wallet shared
with the FitBox e-commerce website and admin portal (one MongoDB Atlas, one
customer account across app + website).

## Features

- **Run tracking** — in-app GPS runs (route, distance, pace, calories) plus the
  device step sensor. Runs keep recording in the background via a location
  foreground service (Android) / background location (iOS). This is the only
  source of activity — nothing is synced from Apple Health / Health Connect.
  Runs are stored on the device first, so history is instant and offline-safe,
  then uploaded; an upload that fails is queued and retried, because saving a
  run is what credits its points and claims its land.
- **Territory game** — a contested land-grab. A run claims **a 25 m corridor
  along its route, plus the whole area it encloses if it closes a loop** — so
  every run that covers ground takes land, while looping still pays several
  times more. Runs in separate areas accumulate as separate holdings rather
  than replacing each other. Overlapping a rival's territory transfers it to
  you. Shared full-screen map + leaderboard. **Weekly seasons** reset every
  Monday 00:00 UTC. See "Territory rules" below.
- **Challenges** — admin-created step/distance goals with a "first N users"
  reward cap; join in-app and claim points on completion.
- **Rewards wallet** — points are won as a **weekly competition**: when a season
  closes, holders are ranked by the territory they hold and only the **top 20**
  are paid, rank 1 taking the largest share (`backend/seasonRewards.js`). Nothing
  is credited per run. Points are redeemable on the website; the value and the
  redemption cap are **configured in the admin portal**, not compiled in
  (defaults: 1 point = ₹0.10, up to 10% of an order).
- **Push notifications (FCM)** — territory attacks, season results and admin broadcasts.
  Every push is also recorded server-side, so the in-app Notifications list is complete even
  if push is off, no device token is registered yet, or the banner was dismissed.
- **Goals & achievements** — targets and badges computed from the user's own runs
  (streak, distance, best pace, territory held, rank).

## Architecture

- **App** — Flutter (Riverpod, go_router, google_maps_flutter, geolocator,
  firebase_messaging).
- **App backend** — `backend/` (Node/Express, Mongoose), deployed on Vercel at
  `https://fit-box-app.vercel.app`. Handles runs, territory, challenges, wallet
  reads, and push. Mutations that credit points are guarded by a shared service
  key (`X-Service-Key` / `WALLET_SERVICE_KEY`).
- **Shared DB** — one MongoDB Atlas, shared with the website and admin portal.
  Auth is the website's JWT (keyed by the customer's Mongo `_id`).

## Territory rules

Implemented in `backend/territoryEngine.js` (pure geometry, unit-tested) and
applied by `backend/territoryService.js`.

| Rule | Value | Why |
|---|---|---|
| Corridor claimed along a route | 25 m each side | every run that covers ground takes visible land, not a hairline sliver |
| Enclosed area | claimed in full when the route closes a loop | keeps looping the winning strategy (roughly 5–7× a same-distance out-and-back) |
| Minimum route length | 150 m, and the route's bbox must span more than the corridor width | a phone lying still produces a wandering GPS trace; without this it would claim land for doing nothing |
| Minimum claim | 200 m² | ignores degenerate geometry |
| Overlap with a rival | subtracted from them, added to you | the contest — they get an "under attack"/"lost" push |
| Season | ISO week, resets Monday 00:00 UTC | past weeks are kept as history |

A claim happens **inside `POST /api/runs`**, so land can't be lost to a dropped
follow-up request. Runs carry a client-generated `clientId` (unique per user),
which makes re-uploading a run idempotent — no duplicate runs, no double points.

### Season rewards

Territory is only worth points **at the end of the week**. When a season closes,
holders are ranked by the area they hold at that moment and the **top 20** are
paid. Nothing is paid per run.

**Rank 1 wins ₹200** (`TOP_REWARD_INR`), and every place below scales down by
rank and by how much land it holds relative to the leader. The award is set in
rupees, not points, so retuning the point value in the admin portal doesn't
change what a season costs — at ₹0.10 first place is 2,000 points; at ₹1 it's
200. A full table of 20 costs about **₹930 per week**:

| Rank | 1 | 2 | 3 | 5 | 20 |
|---|---|---|---|---|---|
| Award | ₹200 | ₹114.60 | ₹82.70 | ₹54.80 | ₹17.50 |

Settlement is idempotent per user per season (ledger key
`season_<season>_<userId>`) and happens lazily on the first territory fetch after
a season closes, so payouts don't depend on a scheduler being configured.
`POST /api/territories/rewards/settle` forces it; `.../rewards/preview` shows the
live table. Rules live in `backend/seasonRewards.js` and are covered by
`backend/test/seasonRewards.test.js`.

The payout table is deliberately **not** shown in the app — it's disclosed in the
points T&C, which the backend generates from the configured values.

Run the rules:

```bash
cd backend && npm test        # node --test, 8 cases
```

## Backend API (app backend)

| Route | Auth | Purpose |
|---|---|---|
| `GET /api/runs`, `POST /api/runs` | user JWT | list / record runs — claims the route's territory; idempotent per `clientId`. Credits **no** points (rewards are weekly) |
| `GET /api/territories`, `POST /api/territories/capture` | user JWT | current-season map + a standalone claim (older builds / re-claiming a past run) |
| `GET /api/territories/rewards/preview` | user JWT | live standings — what the season would pay if it ended now |
| `POST /api/territories/rewards/settle` | service key | pay out a closed season (idempotent per user per season) |
| `GET /api/config/points` | public | live point value, redemption cap and the T&C wording built from them |
| `GET /api/notifications`, `POST /api/notifications/read` | user JWT | the user's event history + mark read |
| `DELETE /api/runs/:id`, `DELETE /api/runs/client/:clientId` | user JWT | delete one of your own runs (territory already claimed is kept) |
| `GET /api/appmaint/leaked-runs`, `POST /api/appmaint/fix-leaked-runs`, `POST /api/appmaint/rebuild-territory` | service key | repair tools for the pre-v1.19.0 cross-account run leak |
| `GET /api/challenges`, `POST /:id/join`, `POST /:id/claim` | user JWT | challenges |
| `… /api/challenges/admin/*` | service key | challenge CRUD (used by admin portal) |
| `GET /api/wallet` | user JWT | balance + ledger |
| `POST /api/push/register` `/unregister` | user JWT | device FCM token |
| `POST /api/push/send`, `GET /api/push/status` | service key / public | admin push |
| `GET /health` | public | liveness + which build is live (`apiVersion`, `commit`, feature flags) |

`POST /api/runs` expects `route` as a GeoJSON LineString in `[lng, lat]` order
(`{"type":"LineString","coordinates":[[lng,lat], …]}`). A bare `[[lng,lat], …]`
array is also accepted for older builds, and a run with no route at all saves
fine (indoor/step-only) — it just can't claim territory.

### Checking what's deployed

`/health` is the only unauthenticated way to tell whether a push actually went
live:

```bash
curl https://fit-box-app.vercel.app/health
# {"status":"ok","apiVersion":"1.18.0","commit":"d34864b","features":{…}}
```

### Required backend env (Vercel)

- `MONGO_URI`, `JWT_SECRET` — shared with the website.
- `WALLET_SERVICE_KEY` — shared service key (also set on the admin backend).
- `FIREBASE_SERVICE_ACCOUNT` — Firebase Admin JSON (raw or base64) for push.

## Releasing

Release builds are signed with a keystore that is **never committed**; without it
the build falls back to the debug key and warns loudly. See
**[`android/RELEASE.md`](android/RELEASE.md)** for keystore generation, the
backup warning, the Firebase fingerprint step (Google Sign-In fails in release
builds without it), and the Play Console checklist.

```bash
flutter build appbundle --release   # upload this to Play
flutter build apk --release         # direct install / testing
```

Local files required to build, all gitignored:
`android/local.properties` (`MAPS_API_KEY`), `android/app/google-services.json`,
`android/key.properties` + the keystore, and `backend/.env`.

## Getting started

```bash
flutter pub get
flutter run                     # device / emulator
flutter build apk --release     # Android release
```

The backend runs from `backend/` (`npm install && npm start`), or is deployed
serverlessly on Vercel.

## Progress

See `PROGRESS.md` for the running development log.
