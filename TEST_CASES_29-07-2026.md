# Test Cases — 29 July 2026 work (App ↔ Website ↔ Admin)

Covers the points economy, challenges, territory seasons, background run, FCM
push, and the admin "FitBox App" section. "Pass" = the Expected column holds.

> Prereq: install the latest app build **FitBox v1.17.0** (in
> `reports/29-07-2026/`) and sign in with a real account; have the admin portal
> and the website open signed in.

## A. Points economy (earn in app → redeem on website)

| # | Scenario | Steps | Expected |
|---|---|---|---|
| A1 | Earn points from a run | Record/finish a ~1 km run in the app | Wallet increases by ~10 points (10 pts/km); a `run_reward` row appears in the ledger. **Never actually worked before v1.18.0** — the run save 500'd, so no reward was ever credited. Re-test explicitly |
| A1b | Run reaches the server | After A1, open admin → FitBox App → Overview / Users | Run count is non-zero and the run appears against the user (before v1.18.0 every run save failed validation, so this read 0) |
| A1c | No double credit on retry | Pull-to-refresh History repeatedly after a synced run | Points credited exactly once — the run is matched on `clientId` and the reward is idempotent per run |
| A2 | Points value shown | Open Wallet → "How points work · Terms" | Shows 1 pt = ₹0.10, 50% redeem cap, no-cash-value terms |
| A3 | 50% cap at checkout | On the website, add an item (say ₹100), have ≥1000 pts, tick "Apply points" | Max applied = 500 pts (₹50); total never drops below 50% of order value |
| A4 | Client == server | Place the A3 order | Charged total equals the cart preview; wallet debited by exactly the applied points |
| A5 | Insufficient points | Apply points you don't have (tamper) | Server clamps to available/allowed; no negative balance, no double-spend |
| A6 | Refund returns points | Cancel/refund a points-paid order | Redeemed points returned to wallet; a refund ledger row appears |
| A7 | Cross-surface balance | Compare wallet in app, website account, admin Users | All three show the same balance (single shared ledger) |

## B. Challenges (admin create → app join/claim)

| # | Scenario | Steps | Expected |
|---|---|---|---|
| B1 | Admin creates a challenge | Admin → FitBox App → Challenges → New Challenge (steps, 2000, 1 day, 50 pts, cap 5) → Save | 201; challenge appears in the admin list as ACTIVE |
| B2 | Appears in app | Open app → Challenges (pull to refresh) | The new challenge is listed with goal / duration / reward / cap |
| B3 | Join | Tap "Join challenge" | Status → in-progress; a deadline (join + durationDays) is shown |
| B4 | Progress | Record a run contributing to the goal | Progress bar/label advances from the user's runs since joining |
| B5 | Claim on completion | Meet the goal before the deadline → "Claim" | Wallet increases by rewardPoints; `challenge_reward` ledger row; button → "Reward claimed" |
| B6 | Reward cap | Have (cap+1) users complete & claim | Only the first `cap` get points; the rest see "Reward limit reached" |
| B7 | Deadline miss | Let the deadline pass without meeting the goal | Cannot claim; challenge shows ended |
| B8 | Edit / delete | Admin edits reward / sets Hidden / deletes | App reflects the change on refresh; deleted challenge disappears (progress rows removed) |
| B9 | Idempotent claim | Tap claim twice quickly | Credited once only (idempotency key) |

## C. Territory — weekly seasons

> Updated 6 Aug 2026 (v1.18.0): a run claims a **25 m corridor along its route**
> plus any **enclosed area** — it no longer has to be a loop. C6–C9 cover that.

| # | Scenario | Steps | Expected |
|---|---|---|---|
| C1 | Capture tags season | Run a loop to claim territory | Your area shows on the map; stored under the current season |
| C2 | Season countdown | Open Territory | "SEASON · RESETS IN Xd Yh" pill matches next Monday 00:00 UTC |
| C3 | Contest transfers | Have a rival loop over your area | Overlap moves from you to them; both areas update |
| C4 | Weekly reset | After Monday 00:00 UTC | Map/leaderboard start empty for the new season; last week no longer counts |
| C5 | Admin view | Admin → FitBox App → Territory | Shows current season, reset date, and the season leaderboard (matches app) |
| C6 | **Non-loop run claims land** | Run ~1 km out and back along a road, save | A visible band along the road appears on the map (≈50 m wide); YOUR TERRITORY grows. Previously claimed a near-invisible sliver |
| C7 | **Separate areas accumulate** | Run in one area, then a second run somewhere else | Both areas remain on the map; REGIONS = 2; YOUR TERRITORY = the sum. The second run must not replace the first |
| C8 | **Loop still pays more** | Compare a loop against an out-and-back of the same distance | The loop claims several times more area |
| C9 | **Standing still claims nothing** | Start a run, leave the phone still for 3–4 min, save | Summary says no territory claimed (route under 150 m); no land appears |
| C10 | **Offline claim is not lost** | Turn on airplane mode, record a run, save, then reconnect and pull-to-refresh History | Summary says it will claim when back online; after the refresh the land and the run points appear |

## D. True background run

| # | Scenario | Steps | Expected |
|---|---|---|---|
| D1 | Background keeps recording | Start a run → background the app / lock the screen → walk 2–3 min → reopen | Time, distance and steps kept counting; route continued (no freeze) |
| D2 | Foreground-service notification (Android) | While recording | One ongoing "FitBox — recording run" notification; tapping returns to the app |
| D3 | Pause/resume | Pause, wait, resume (incl. while backgrounded) | Elapsed pauses; distance doesn't bridge the pause gap |
| D4 | Finish | Finish the run | Notification/service clears; run saved; points credited (A1) |

## E. Push notifications (FCM)

| # | Scenario | Steps | Expected |
|---|---|---|---|
| E1 | Token registered | Sign in on v1.17.0, allow notifications | User's `fcmTokens` gains this device; admin Users shows push = ✓ |
| E2 | Admin broadcast | Admin → FitBox App → Push → all users → Send | Result "Sent to N devices"; registered devices receive it |
| E3 | Foreground display | Send while the app is open | Notification is shown (app surfaces it locally) |
| E4 | Territory-capture push | Rival takes your territory | You receive "under attack / territory lost" |
| E5 | Config status | Admin Push tab | Shows "Push is configured and live" (status = configured) |

## F. Admin "FitBox App" section

| # | Scenario | Steps | Expected |
|---|---|---|---|
| F1 | Access control | Hit `/api/app/analytics` without admin login | 401 |
| F2 | Overview | Open Overview | User/run/points/challenge/territory stats + 14-day runs chart render |
| F3 | Points economy | Overview → economy card | Earned/redeemed/by-source and outstanding liability (₹0.10) shown |
| F4 | Users | Users tab | App users with points, runs, distance, territory, push flag; search works |
| F5 | Env missing | (If `WALLET_SERVICE_KEY`/`APP_API_BASE` unset) open Challenges/Push | Clear upstream error, not a crash; Overview/Users still work |

## G. Regression / cross-repo

| # | Scenario | Expected |
|---|---|---|
| G1 | Website login (Google + email) | Works; passwordless accounts get a clear 401, not a 500 |
| G2 | Existing store flows | Products / Orders / Customers / Refunds unaffected in admin & website |
| G3 | Guest mode (app) | Guests browse; account actions still gated behind sign-in |
| G4 | No health sync | No Apple Health / Health Connect data ever appears — in-app runs only |
