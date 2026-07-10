# Deploying the FitBox App Backend to Vercel

This backend is a **subfolder** (`backend/`) of the `Fitbox-41/FitBox-App` repo. It runs as a
Vercel serverless function (`server.js` exports the Express app; `vercel.json` routes all requests to it).

## What you need
- Access to the **company Vercel account**.
- The repo `Fitbox-41/FitBox-App` connected to that Vercel account (GitHub integration).
- Two environment values (both already in your local `FitBox_App/backend/.env` — copy from there, do **not** commit them):
  - `MONGO_URI` — the shared MongoDB Atlas connection string.
  - `JWT_SECRET` — **must be identical** to the website's `JWT_SECRET` (see `FitBox_Website/.env`). This is what lets the backend verify website-issued logins.

## Option A — Vercel Dashboard (recommended)
1. Go to **vercel.com → Add New… → Project → Import Git Repository** and pick **`Fitbox-41/FitBox-App`**.
2. In **Configure Project**:
   - **Root Directory:** click *Edit* and set it to **`backend`**.
   - **Framework Preset:** *Other*.
   - Leave Build/Output/Install commands as defaults.
3. Expand **Environment Variables** and add (for **Production** and **Preview**):
   - `MONGO_URI` = *(value from `backend/.env`)*
   - `JWT_SECRET` = *(the website's secret, from `FitBox_Website/.env`)*
4. Click **Deploy**.
5. When it finishes, open `https://<your-project>.vercel.app/health` → you should see
   `{"status":"ok","service":"FitBox App Backend"}`.

## Option B — Vercel CLI (if the CLI is logged into the company account)
```bash
cd backend
vercel link            # link to a new/existing project under the company scope
vercel env add MONGO_URI production
vercel env add JWT_SECRET production
vercel --prod
```

## After deploying
- Send the **production URL** (e.g. `https://fitbox-app-backend.vercel.app`) back so the app can be
  pointed at it. The app reads it from `AppConfig.appApiBase`; we build with
  `--dart-define=APP_API_BASE=https://<your-url>` (or bake it into `app_config.dart`).
- Quick check that auth verification works end-to-end (after the app is pointed at it): a logged-in
  request to `GET /api/wallet` with a valid token returns a wallet; an invalid token returns 401.

## Notes
- **Never commit `.env`** — it's gitignored. Secrets live only in Vercel's Environment Variables.
- `JWT_SECRET` here must always equal the website's; if the website rotates it, update it here too.
- MongoDB Atlas **Network Access** must allow Vercel (it already does, since the website runs there).
