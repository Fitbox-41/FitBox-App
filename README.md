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
- **Territory game** — a contested land-grab: run a loop to claim the enclosed
  area; overlapping a rival's territory transfers it to you. Shared full-screen
  map + leaderboard. **Weekly seasons** reset every Monday 00:00 UTC.
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

## Backend API (app backend)

| Route | Auth | Purpose |
|---|---|---|
| `GET /api/runs`, `POST /api/runs` | user JWT | list / record runs (credits 10 pts/km) |
| `GET /api/territories`, `POST /api/territories/capture` | user JWT | current-season map + capture |
| `GET /api/challenges`, `POST /:id/join`, `POST /:id/claim` | user JWT | challenges |
| `… /api/challenges/admin/*` | service key | challenge CRUD (used by admin portal) |
| `GET /api/wallet` | user JWT | balance + ledger |
| `POST /api/push/register` `/unregister` | user JWT | device FCM token |
| `POST /api/push/send`, `GET /api/push/status` | service key / public | admin push |

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
