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
- **Rewards wallet** — points earned from runs (10 pts/km) and challenges;
  1 point = ₹0.10, redeemable for up to 50% of an order on the website.
- **Push notifications (FCM)** — challenge/territory alerts and admin broadcasts.

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

Run the rules:

```bash
cd backend && npm test        # node --test, 8 cases
```

## Backend API (app backend)

| Route | Auth | Purpose |
|---|---|---|
| `GET /api/runs`, `POST /api/runs` | user JWT | list / record runs — credits 10 pts/km **and** claims the route's territory; idempotent per `clientId` |
| `GET /api/territories`, `POST /api/territories/capture` | user JWT | current-season map + a standalone claim (older builds / re-claiming a past run) |
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
