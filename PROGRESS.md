# FitBox App — Progress Log

A running development log. Newest entry on top. Weekly reports are added here each week.

---

## 23 August 2026 — the new logo, everywhere; **v1.1.1+3**

The owner's replacement logo finally arrived (`logo.svg` / `logo.webp`, same artwork
in two formats). It's the same FitBox wordmark, redrawn with a **metallic silver
"Fit Sports"** and a glossy bevelled red "BOX" — where the old one was flat charcoal
and flat red. That single change to the artwork is what made this more than a file
swap.

**The silver is the whole problem.** Its luminance measures 0.60–0.89, so on the
light theme's `#F2F4F8` backdrop half the logo simply dissolves — "SPORTS" was
unreadable. Everywhere the logo lands now gets the treatment it needs:

- **Dark theme** — the artwork as drawn. Silver on near-black is what it was
  designed for.
- **Light theme** — the metal is remapped to a graphite gradient. Not flattened to
  a silhouette: luminance is *rescaled*, so it still reads as lit metal. Only
  low-saturation pixels move, so the red keeps its own shading, and the hand-over
  is feathered or the anti-aliased pixels between the two halves show a seam. This
  is the same split the old assets used (charcoal on light, white on dark), applied
  to a gradient instead of a flat colour.
- **App icon** — on the app's own near-black, not white. A white icon plate would
  have hidden the silver exactly the way the light theme did.

**Everything comes from one source now.** `tool/gen_logo_assets.py` builds both
in-app marks, the three launcher layers and the five web icons from
`assets/brand/logo.svg`; `assets/images/logo.png` is gone (it was only ever a
launcher source, and it was being bundled into the APK for nothing). Hand-editing
any of the PNGs will be overwritten — that's deliberate, it's how the variants stay
in step.

**Source quality.** The supplied vector is an auto-trace of a raster: crisp
silhouettes, but the gradients arrive as ~300 flat facets. It's rendered at 4400 px
and the *interior* colour smoothed without touching the alpha — blur the
premultiplied colour, divide the blurred alpha back out, then restore the original
alpha — so the banding goes and the edges stay exactly as traced.

### Launcher icons, properly this time
The old setup generated legacy square icons only, so Android 8+ drew the wordmark
shrunken inside a white rounded square. Now: **adaptive icons** (foreground +
`#12161A` background), a **monochrome layer** for Android 13 themed icons, and a
`drawable-night/launch_background.xml` so dark-mode users stop getting a white flash
before the app's first frame.

Sizing the adaptive foreground took two attempts, and the reason is worth recording:
two multipliers stack. `flutter_launcher_icons` wraps the layer in a 16% inset (so
only 0.68 of the drawn artwork reaches the 108dp canvas), and the launcher then
shows roughly the middle 72dp and may round it. A 2.5:1 wordmark reaches further
into the corners than its width implies — its tips sit at 0.537× the width from the
centre. The first build put the mark at 0.90 and **the X clipped on the phone**;
0.80 lands it ~4dp inside the mask, verified on device under both the squircle and
the circular mask.

Verified on device: splash in dark *and* light theme, the launcher icon under two
mask shapes, `flutter analyze` clean, widget test passing.

---

## 13 August 2026 (later) — owner review changes; **v1.1.0+2**

Owner approved the app and asked for final changes; the full meeting transcript drove this, not the
summary (which overstated a few items — see "not doing" below). Report:
`reports/13-08-2026/FitBox_Android_v1.1_Report_13-08-2026.pdf`, APK `FitBox_v1.1.0.apk`.

**Two decisions from 7 Aug were reversed, on the owner's instruction:**
- **Per-run points are back** — 10 pts/km (₹1/km) credited on every saved run. The reasoning was that
  someone running 2 km a day otherwise gets nothing and leaves. The weekly territory prize *also* stays;
  the two run in parallel.
- **Territory no longer resets weekly.** "टेरिटरी उड़ाओ मत" — it's meant to be a record of everywhere
  someone has run, and only another player invading should shrink it.

**Because territory is permanent, the weekly prize had to change basis.** Ranking on total area held —
the literal wording in the meeting — would hand the prize to whoever built the biggest holding first,
every week, forever. It now ranks **ground claimed during that week** (new `SeasonProgress` collection),
so the contest stays winnable. Agreed with Gautam before implementing. The map gained **All time / This
week** views to match.

**Also shipped:** checkout applies the best discount automatically (tick-box, points field and
25/50/Max buttons removed — "कस्टमर पजल मारेगा"); "Wallet" → "Earned" in customer copy; **99-day FIFO
point expiry** with every expiry written to the ledger; territory owner identity (tap a patch → name,
rank, area, km, steps, regions) plus a ranked owner list under the map.

**Anti-abuse added unprompted:** at ₹1/km, distance now has cash value, so a car journey would earn
money. Runs at an implausible pace still save and still claim land but earn no points, and the T&C says
so.

### Bug — notifications reaching the wrong account
Reported from two-account testing: signed out of A, into B on the same phone, and B capturing A's land
delivered **A's** "territory lost" push to the handset. Two independent holes:
`logout()` never called `/push/unregister` (`PushService.unregister()` had **zero callers** repo-wide),
and `/push/register` never pulled the token off its previous owner. Fixed both — the server side is
authoritative since it also repairs already-poisoned devices and survives a logout that never reached
it. Broadcasts now dedupe tokens too. Live data confirmed one token was on **both** test accounts.

### Migrations run against production
1. Territory merged to one lifetime doc per user (Gautam 17,393 m², Klaus 18,761 m²); dropped the stale
   `{userId, season}` unique index for `{userId}`.
2. Point expiry backfilled — earliest expiry 4 Nov 2026, nothing overdue.
3. Shared device token released.

**A migration bug caught before it did damage:** the first backfill set `remaining = amount` on every
historical credit, which would have marked **11,195 points as live on an account holding 6,000** —
points spent months ago counted again — and expiry would later have driven the balance negative. It now
spreads the *current balance* over the newest credits (what FIFO implies), and records an
`opening_balance` credit for any balance no ledger row explains (39 pts on one account, left over from
the earlier reset). Both accounts verified: buckets == balance exactly.

### Not doing (checked against the transcript)
- **Location permission timing** — the current behaviour was explained in the call and accepted
  ("ठीक है ठीक है ठीक है"). No change.
- **Theme selection at startup** — "ना ही रखो बट ठीक है चलो रहने दो" → left as is.
- **Guest mode** — kept (confirmed with Gautam).
- **OTP login** — depends on a paid website-side service.

### Blocked
**The new logo was never sent** ("ओ भेजा नहीं था सर उसने"). Three asset files + `LogoBadge` + a launcher
icon regen once it arrives — that is the one thing standing between this and a final Android sign-off.

Verified: 24 backend tests, `flutter analyze` clean, widget test passing, website + admin build, APK
installed on device, backend live at `apiVersion 1.1.0`.

---

## 13 August 2026 — iOS compiles on CI; challenge push; admin fixes

**✅ The iOS app builds, with real config.** Codemagic `ios-validate` (Mac mini M2): pods resolved,
unsigned release build succeeded → `Runner.app.zip` (~27.7 MB). This was the only thing that could not
be verified from Windows. iOS is now blocked purely on a paid Apple Developer account — signing,
TestFlight, push and device testing — not on code.

**A false green first.** The initial passing build had *empty* configuration: the restore step ran
`base64 --decode` on unset variables, which succeeds and writes empty files, and neither an empty
`GoogleService-Info.plist` nor an empty Maps key breaks compilation — they only fail at runtime. So a
green build wrongly implied the config was wired. Every restore step now fails immediately naming the
missing variable and its group, and verifies the decoded file looks like the file it should be. The
variable group was then populated and the re-run passed properly.

Also worth noting for later: `ios-validate` only consumes `GOOGLE_SERVICE_INFO_PLIST` and
`MAPS_API_KEY_IOS`. `GOOGLE_SERVICES_JSON` and `MAPS_API_KEY_ANDROID` sit in the same group for the
`android-release` workflow, which isn't needed while Android builds locally on Windows.

Two build failures were fixed to get there, both worth recording:

- **Codemagic rejected the whole config file.** `ios-testflight` declared `publishing.auth: integration`
  referring to an App Store Connect integration that doesn't exist yet, and a single unresolvable
  reference invalidates *every* workflow — so it also blocked `ios-validate`, the one workflow needing
  no Apple account. Publishing block commented out with restore instructions.
- **`pod install` failed:** *"Specs satisfying the Flutter dependency were found, but they required a
  higher minimum deployment target."* The Podfile pinned iOS 14.0 (chosen from
  `google_maps_flutter_ios`, the highest floor visible from Windows), but the Flutter pod itself wants
  more. Raised to **iOS 15.0** across the Podfile, the pod post-install hook and the Xcode project —
  covers iPhone 6s (2015) and later.
  - Root cause was `flutter: stable` in CI: the build followed whatever Flutter shipped most recently
    rather than the version developed against, so the deployment floor moved with nothing in the repo
    changing. **Pinned to 3.44.1** to match local.

### Admin + app
- **Creating a challenge now announces it.** Previously a new challenge sat unseen until someone opened
  the Challenges screen. An active challenge now pushes to every app user *and* writes an in-app
  notification each, so it still lands for users with push disabled. Audience is app users only
  (registered device or has signed in from the app) — website-only customers aren't pinged.
  Awaited rather than fire-and-forget, since serverless can freeze the function once the response is
  sent. Returns `announced: {recipients, sent}`.
- **"Service authentication required" on challenge/push** was the admin backend's `WALLET_SERVICE_KEY`
  being unset — it defaulted to `''`, so it sent an empty header and surfaced the app backend's generic
  403. Confirmed by probing: the app backend returned **403 not 503**, proving its own key was fine.
  Fixed by the owner setting the env var; the code now fails early with an actionable message, reports
  a 403 from upstream as a key mismatch, and exposes `GET /api/app/config-check` for one-look diagnosis.
- **Points settings moved** from Website Settings to **FitBox App → Points**, where they belong.
  Store Settings no longer sends the points fields at all — it had held its own copies, so saving a
  delivery-fee change could have silently overwritten the economy with stale values.

---

## 11 August 2026 (close of day, later) — iOS taken as far as Windows allows

v1.0.0 released on GitHub (tag `v1.0.0`, APK + PDF attached) after the Maps key was restricted.
Then pushed iOS to the limit of what can be done without a Mac. Status doc: **`ios/IOS_STATUS.md`**.

- **⚠ iOS needs its own Maps API key.** A Google Maps key accepts exactly **one** application
  restriction — *Android apps* **or** *iOS apps*, never both. The key just restricted to the Android
  package will be **rejected on iOS**. A second key restricted to bundle id `com.fitboxsports.app`
  must be created before the first iOS build.
- **Deployment target 13.0 → 14.0.** `google_maps_flutter_ios` 2.18.4 declares `s.platform = :ios,
  '14.0'`, so `pod install` would have **failed on the very first Codemagic build**. Caught by reading
  the plugin's podspec rather than waiting for CI to fail.
- **Added `ios/Podfile`** (hand-written — Flutter only generates it on a Mac), pinning iOS 14.0 and
  trimming `permission_handler` to the permissions actually used, so App Review isn't asked to explain
  permissions the app never requests.
- **Added `ios/Runner/PrivacyInfo.xcprivacy`** — Apple requires a privacy manifest for submission.
  Declares precise location, email, name, fitness and purchase data, plus the required-reason APIs
  (UserDefaults, file timestamp, disk space, boot time). Kept consistent with the published policy.
- **`ITSAppUsesNonExemptEncryption = false`** so TestFlight stops asking export-compliance on every
  upload.
- **`codemagic.yaml` would have failed on the first run** — `google-services.json`,
  `GoogleService-Info.plist` and the Maps keys are all gitignored, so they don't exist on a fresh CI
  clone. Both workflows now restore them from Codemagic secrets before building.
- **Deliberately not added: the `aps-environment` entitlement.** It fails signing until the Apple App
  ID actually has Push enabled, so it belongs with the Apple-account work, not now.

Still requires a Mac / Apple account: `pod install` + first compile, signing, APNs, registering the
widget target, Live Activity, device testing, TestFlight.

---

## 11 August 2026 (close of day) — v1.0.0 signed, configured and handed over

Wrap-up of the release. Artifacts in `reports/11-08-2026/`: signed `FitBox_v1.0.0.apk`,
`FitBox_v1.0.0.aab`, and `FitBox_Android_v1.0_Report_11-08-2026.pdf` for the owner.

- **Firebase now trusts the release certificate.** Both fingerprints are registered and the refreshed
  `google-services.json` is in place — verified it carries the release hash `a83d9245…` **and** the
  debug hash `f942fb0e…`, so `flutter run` keeps working alongside signed builds. Google Sign-In was
  going to fail in release builds without this. `MAPS_API_KEY` confirmed present in `local.properties`.
- **Rebuilt both artifacts against the new config** and reinstalled on device — the APK previously on
  the phone had been built with the old `google-services.json`. Signature re-verified as
  `CN=FitBox Sports` (SHA-1 `a83d9245…`).
- **Keystore backed up by the owner-developer** (confirmed). `android/RELEASE.md` documents
  regeneration, the Play App Signing recommendation, and the fingerprint step.

### First live weekly settlement — the trigger works
Season **2026-W32** closed on Monday 10 Aug and settled automatically at `18:32:51Z`, recorded in
`season_settlements`, without any manual action or scheduler. That was the one mechanism that had never
run in production.

It paid **nobody**, correctly: territory was wiped during the 7 Aug reset and no runs have been recorded
since, so there was no one to rank. **The trigger is proven; the payout is not.** Settling a season with
real holders — the ₹200 prize, the winner notification, the wallet credit — is still unvalidated and is
the next thing worth testing, either at the 17 Aug rollover or by forcing a settlement once both test
accounts hold land.

Current season is **2026-W33** (closes Mon 17 Aug 00:00 UTC). Both test accounts are clean:
6,000 / 1,000 points, zero runs, zero territory.

---

## 11 August 2026 (later) — release readiness + security review; **versioned as v1.0.0**

A readiness audit before handing the app to the owner. Version restarts at **1.0.0+1** for the first
release. Report: `reports/11-08-2026/FitBox_Android_v1.0_Report_11-08-2026.pdf`; artifacts
`FitBox_v1.0.0.apk` and `FitBox_v1.0.0.aab`.

### Blocker — release builds were signed with the debug key
`signingConfig = signingConfigs.getByName("debug")`. That key ships with every Android SDK install and
is the same for everyone, so the build was both unpublishable (Play rejects it) and forgeable.

- Generated a production keystore; signing now reads `android/key.properties`, with a **loud warning
  fallback** to debug so a machine without the keystore can still build for testing.
  Keystore + passwords are gitignored — verified not tracked.
- Release APK/AAB now verify as `CN=FitBox Sports` via `apksigner`.
- Enabled **R8 shrink + obfuscation** with rules for Flutter, Gson-backed notifications and Play Core.
- `android/RELEASE.md` documents keystore generation, backup ("the first key to publish is the only
  key that can ever update"), and the store checklist.
- ⚠ **The release SHA-1 must be registered in Firebase or Google Sign-In breaks in release builds** —
  Google authorises by signing certificate and only the debug cert was registered. Fingerprints are in
  `android/RELEASE.md`.

### Security review of the app + backend
**Verified sound:** no secret ever committed (full history checked), Maps key injected from an untracked
file, every mutating endpoint behind user auth or the service key, wallet mutations server-only and
fail-closed, users scoped to their own data, HTTPS throughout, token in encrypted device storage,
no high/critical dependency advisories.

**Fixed:**
- **No rate limiting** on the app backend — territory capture and run upload do real geometry work and
  could be hammered by any authenticated client. Added a per-IP throttle + 1 MB body cap. Note this is
  best-effort in serverless (per-instance counters); Vercel's edge protection is the primary layer.
- **CORS allowed any origin** → restricted to known web origins (the mobile app is unaffected by CORS).
- **Mass assignment in `POST /runs`** — the body was spread into the document, so a crafted request
  could set `_id`, `claimedAreaSqm` or timestamps. Replaced with an explicit allow-list; everything
  server-authoritative is derived.
- Service-key comparison is now constant-time; JWT verification pins `HS256`.

**Noted, not changed:** JWT lifetime is 30 days with no server-side revocation — a signed-out device's
token stays valid until expiry. Worth revisiting before real volume.

### Dead UI removed
- Settings showed a hardcoded **"v1.1.0"** while the app was on 1.20 → now read from the package.
- Settings **Privacy** and **About** rows did nothing; the landing page's **Terms & Privacy Policy**
  were underlined like links with no handler. All now open the published pages — required, since app
  stores expect a reachable privacy policy for an app collecting location. Added a Terms row.
- Removed a permanently disabled **Map layers** button and the unused `mock_data.dart`.
- **Apple Sign-In kept** as requested (to be enabled soon).

### Privacy policy
Rewrote the website policy to cover the mobile app: precise GPS collected **only while a run is
recording** (never otherwise), motion data, push token, explicitly **no Apple Health / Health Connect**,
retention per data type, deletion rights, and the processors involved. It also states plainly that
**claimed territory is visible to other players next to the user's display name** — the one thing a
user could reasonably be surprised by, previously undisclosed.

---

## 11 August 2026 — Android feature complete, shipped v1.20.0+42

Closed out the remaining gaps identified in the completion review, so every screen now runs
on live data. **Progress report:** `reports/11-08-2026/FitBox_Android_Progress_Report_11-08-2026.pdf`
(5 pages, includes the iOS status section). APK: `reports/11-08-2026/FitBox_v1.20.0.apk`.

- **Notifications are real.** The screen was a hardcoded list — invented place names
  ("SoHo"), an invented rival ("J. Rivera") and a rewards model that no longer exists.
  Events are now persisted server-side inside `fcm.notifyUser`, so the in-app history is
  written whenever a push is sent and survives push being off, no device token yet, or a
  dismissed banner. New `Notification` model + `GET /api/notifications` and
  `POST /api/notifications/read`. The screen marks everything read on open and handles
  guest / empty / error states.
- **Season winners are told.** Settlement previously paid out silently — a user could win
  the weekly prize and never know. Every paid place now gets a push + in-app notification
  with its rank and points.
- **Goals are computed from real activity.** Daily steps, weekly distance and weekly runs
  come from the user's own runs; badges unlock on genuine milestones (first run, a computed
  consecutive-day streak, 10 km total, best pace, territory held, rank 1). Previously all
  six badges and all three progress bars were hardcoded.
- **Run delete reaches the server.** `DELETE /api/runs/:id` and `/api/runs/client/:clientId`,
  scoped to the caller's own runs, so a deleted run no longer reappears on the next sync.
  Territory already claimed is deliberately left alone — it's a union that can't be unpicked
  one run at a time, and releasing land on delete would be an obvious exploit.
- **Top prize is owner-configurable** (admin → Website Settings → FitBox Points): rank 1's
  award in rupees, with places 2–20 derived from it. The admin page previews the resulting
  prize table and the maximum weekly cost, since that knock-on was otherwise invisible until
  a season settled.
- `seasonRewards` now requires the push stack lazily, keeping the payout maths unit-testable
  without `firebase-admin` installed.

Verified: `flutter analyze` clean, widget test passing, backend 19/19, both frontends build,
APK installed on device, backend deploy confirmed live via `/health`.

---

## 7 August 2026 — points config, cross-account leak, weekly rewards (v1.19.0+41)

### Mentor-requested points changes (the two planned below — done)
- **Redemption cap is now 10%** and **no longer stated on the cart/checkout**. Those screens show
  "*Terms and conditions apply" linking to the Terms page; the exact rate and cap stay disclosed
  there and in the app's wallet T&C. The server still clamps, and its rejection message quotes the
  allowance ("you can redeem at most N points") rather than the percentage rule.
- **Point value + cap are now admin-configurable, server-side.** Both live on the shared `settings`
  document (admin → Website Settings → *FitBox Points*), so changing them needs **no website deploy
  and no app release**. Consumers all read it: website checkout clamp, cart preview, wallet page,
  the published Terms copy, the admin liability figure (was a hardcoded `0.1`), and the app via the
  new public `GET /api/config/points` — which also returns the **T&C wording written from the
  configured numbers**, so the published terms can't drift from what checkout applies.
  Saving a new rate warns what the outstanding liability becomes first, since it re-prices every
  point already issued.

### Bug — one account could take another's runs, points and territory (critical)
Reported from two-account testing: signing in as account 2 showed account 1's runs, points and
territory as its own, and after a contest run the land ended up back with whoever signed in last.

**Cause:** run history was cached under a single device-wide key (`recorded_runs`) and `logout()`
only cleared the JWT. So account 2 read account 1's runs — and yesterday's "queue anything the
backend doesn't have" retry then **uploaded them under account 2**, transferring the points and
claiming the territory. Signing back in re-ran the same trick in the other direction.

- History is now **stored per user id**, reset whenever the signed-in user changes, and never
  uploaded by an account that didn't record it. The old shared cache is deleted on upgrade (those
  runs already exist server-side under their real owner).
- `walletProvider` and `territoriesProvider` now key on the signed-in user, so a switch refetches
  instead of showing the previous account's balance/land from cache.
- **Repair tools** for the data this already corrupted (service key):
  `GET /api/appmaint/leaked-runs` reports runs whose `clientId` appears under more than one account;
  `POST /api/appmaint/fix-leaked-runs {confirm:true}` keeps the earliest upload, deletes the copies
  and reverses the points they paid; `POST /api/appmaint/rebuild-territory {confirm:true}` replays
  the season's runs in chronological order to rebuild a correct map (territory is a union, so a
  wrong claim can't simply be subtracted back out).

### Reward model — weekly competition instead of per-run credit
Points are no longer credited when a run ends (`POINTS_PER_KM` is gone). A season is a contest:
when it closes, holders are ranked by the territory they hold at that moment and **only the top 20
are paid** (`backend/seasonRewards.js`). **Rank 1 wins ₹200**; every place below scales down by rank
and by land held relative to the leader (rank 2 ≈ ₹114.60, rank 3 ≈ ₹82.70, rank 20 ≈ ₹17.50) — a
full table of 20 costs about **₹930/week**. The award is defined in **rupees, not points**, so
retuning the point value in admin doesn't change what a season costs.

- Settlement is **idempotent per user per season** (ledger `season_<season>_<userId>`), so a retry
  can't double-pay. It runs lazily on the first territory fetch after a season closes, so payouts
  don't depend on a scheduler existing; `POST /api/territories/rewards/settle` (service key) can
  also be called directly, and `GET /api/territories/rewards/preview` shows the live standings.
- The ranking, the top-20 limit and "territory carries no value until the season closes" are
  **written into the T&C** (website Terms + in-app) but not surfaced in the app UI, as requested.
- Tests: `backend/test/seasonRewards.test.js` (9 cases) covers top-20 truncation, monotonic payouts,
  area weighting, pot conservation, and that no paid place rounds to zero. 17 backend tests total.

### Test data reset (live DB, requested)
Both test accounts were wiped back to a clean slate for two-account testing. The state beforehand was
itself evidence of the leak: **kl4us.carol1ne held 4 runs and 39 points it never earned** (account 1's
runs re-uploaded under it), and glasgotra578 had drifted to 6,134.

- Deleted 7 runs and 2 territory documents across both accounts, plus the 7 activity-reward ledger
  rows that belonged to them; order history (redemptions/refunds) was left intact.
- `glasgotra578@gmail.com` → **6,000 pts**, `kl4us.carol1ne@gmail.com` → **1,000 pts**, each with an
  `admin_adjustment` ledger row so the balance is still explained by the ledger.
- Season settlement markers cleared so a season can be settled again while testing.
- Verified no other user had any runs or territory, so nothing else was touched.

Verified: `flutter analyze` clean, widget test passing, backend 19/19, website + admin frontends
build. APK → `reports/07-08-2026/FitBox_v1.19.0.apk`.

---

## Planned — 7 August 2026 (points config, mentor-requested)

Target: **the Android app is wrapped up by 10 August 2026**, so these land first.

1. **Redemption cap 50% → 10%, and stop stating it at the point of sale.** The cart currently prints
   "1 point = ₹0.10 · Redeemable up to 50% of order (Max N Pts)". The mentor wants that replaced with a
   simple **`*` + "Terms and conditions apply"** linking to the Terms page — the exact value and cap stay
   disclosed in the **legal T&C** (website Terms page + in-app wallet T&C), just not spelled out on
   cart/checkout. The server-side clamp is unchanged, so over-applying is still clamped.
2. **Make the point value and the cap configurable from admin → FitBox App**, held **server-side** and
   read at runtime by the website checkout, the app and admin analytics — **changing a value must not
   need an app rebuild or a store update**. The **T&C copy must render the configured values**, so
   editing them in admin updates what users see in the app and on the website Terms page.
   - Replaces today's compile-time constants (`FitBox_Website/Backend/Utils/points.js`,
     `Frontend/src/config/points.js`), which stay as the offline/fallback default. The admin liability
     figure (`valueInr` in `FitBox_Admin/Backend/routes/app.js`) must read the same config.
   - Note: changing the value **re-prices every existing balance** — the admin screen should show what
     the outstanding liability becomes before saving.

Also queued (Gautam, on-device): more runs in different areas, and a **second account** to exercise the
contest path — running over another user's land must subtract it from them. That path is unit-tested but
has never been run by two real users.

---

## 6 August 2026 (later) — on-device test fallout: runs never saved, territory reworked (v1.18.0+40)

First real on-device testing (3 recorded runs) surfaced four issues. Investigating them turned up a
fifth, bigger one.

- **Runs were never reaching the backend.** `RunActivity.toBackendJson()` sent `route` as a flat
  `[[lat,lng]]` array and omitted `endedAt`, but the Mongoose schema requires a GeoJSON
  `{type, coordinates}` in `[lng,lat]` order — so **every** `POST /api/runs` failed validation and
  500'd. Consequences: runs lived only on the phone (reinstall = history gone), the **10 points/km
  reward had never been credited to anyone** (that code sits after the failing `save()`), and admin
  analytics reported 0 runs. Reads were broken the same way (`json['route'] as List` on a Map).
  Fixed on both sides: the app sends proper GeoJSON and parses either shape; the backend normalises
  array *or* object, and tolerates runs with no route at all (indoor/step-only).
- **Territory rework — the actual USP fix.** Land was claimed **only from the area a closed loop
  encloses**, so a big out-and-back road run claimed a hairline sliver (measured: a 5 km out-and-back
  claimed 4,867 m² — invisible on the map). That's why a big run "showed no territory" while a loopy
  one did. A run now claims **a 25 m corridor along its route unioned with any enclosed area**, so
  every run takes land in proportion to ground covered while loops still pay ~7× more. Same 5 km
  out-and-back now claims ~115,000 m². Guarded by `MIN_ROUTE_METRES = 150` + a bbox-spread check so
  GPS jitter while stationary claims nothing (it previously would have taken 2,061 m²).
  - The engine itself was **not** the bug — verified it already unioned disjoint areas into a
    MultiPolygon correctly. Territories in different areas always accumulated; there just wasn't
    enough area to see.
- **Territory can no longer be silently lost.** Claiming was a separate client call whose failures
  were swallowed by `catch (_) {}` — a cold start or a dropped connection lost that run's land
  permanently. Now `POST /api/runs` claims server-side as part of saving the run, runs carry a
  `clientId` (unique per user) so retries are idempotent, and any run that fails to upload is queued
  and retried on next launch or pull-to-refresh. Shared logic lives in `backend/territoryService.js`
  so the run-save and `/capture` paths can't drift.
- **Activity screen lag.** `RecordedRuns._hydrate()` published state only *after* awaiting the network
  fetch, so History sat empty until that finished (or timed out) despite the local cache being read
  first. Now it paints from local storage immediately and merges the backend copy in the background.
- **Finishing a run didn't go anywhere.** Save awaited two sequential network calls with no spinner
  (up to ~40 s on a cold start) before navigating. Now the run is stored locally and the summary opens
  instantly; the upload continues in the background and the territory banner resolves itself
  (claiming… → "+115,000 m²" → or an honest reason it claimed nothing). Every exit from the summary
  after a run lands on **History** with the new run on top.
- **Territory screen** now shows REGIONS (how many separate holdings) next to area and rank.
- **Tests.** New `backend/test/territoryEngine.test.js` (`npm test`, 8 cases) locks in: out-and-back
  claims a corridor, loops still beat it 5×, standing still claims nothing, separate areas accumulate
  as a MultiPolygon, re-running the same ground doesn't inflate the total, and a rival running through
  your land takes it. `flutter analyze` clean, widget test passing, release APK built →
  `reports/06-08-2026/FitBox_v1.18.0.apk`.
- **Deploy note:** the app changes need the app backend deployed to work — v1.18.0 expects
  `claimedAreaSqm` from `POST /api/runs`.

---

## 6 August 2026 — pulled Diwakar's work; fixed a reverted point value

Pulled all three repos before resuming development (app was already current; website +13 commits,
admin +5 — all fast-forward, nothing of ours lost).

- **Diwakar's additions.** Website: PhonePe payment integration, PDF invoice generation, Under99 page,
  responsive Header/Footer, dynamic store settings + sale ribbon. Admin: order management (filtering,
  status updates, tracking, Excel analytics export), Store Settings page, product management, dashboard.
- **Regression fixed — point value had reverted ₹0.10 → ₹1.** His checkout rework (`f67158b`) was based
  on the **pre-rewrite** history (where the value was still ₹1), so the merge silently overwrote the
  agreed rate in three places: the server clamp (`orderController.js`), the cart preview (`Cart.jsx`)
  and the wallet page balance (`WalletPage.jsx`). Every point was worth 10× too much, contradicting the
  website Terms page (still correctly ₹0.10) and the admin liability figure (`valueInr: 0.1`).
  His 50% cap, the idempotency guard and the new refund-on-cancel/failed-order logic were all fine and
  were kept.
- **Hardened against a repeat.** The point value + 50% cap now live in **one module per side**
  (`Backend/Utils/points.js`, `Frontend/src/config/points.js`) with a comment stating why they must not
  change without sign-off, so the cart, the server clamp and the wallet page can no longer drift apart.
  Verified: `maxRedeemablePoints(1000)` = 5000 pts = ₹500 = 50%; frontend builds clean.
- **Also committed** the root `.gitignore` (`.env`, `node_modules`) — it existed locally since July but
  was never tracked. Confirmed no `.env` or `node_modules` was ever committed.
- **Note — attribution trailers are back in the website repo.** The merge resurrected the pre-cleanup
  copies of five July commits (`d61a77f`, `f926514`, `d667534`, `dfd7bd2`, `b9fefd8`), which still carry
  a co-author trailer; website history also now contains that July work twice (old + rewritten hashes),
  joined at merge `29a421d`. App and admin are clean. Removing them needs another history rewrite, which
  would break Diwakar's clone again — to be coordinated, not done unilaterally.
- **Root cause of all of the above:** his clone was never reset after the 29 July force-push, so he
  committed on the old history and merged it back.

---

## 29 July 2026 (evening) — go-live, user segregation, wallet page, fixes

Session close-out across app / website / admin. All deployed to `main`.

- **FCM verified live + content seeded.** `push/status` = configured; seeded two starter challenges
  (Weekend Step Sprint, 5K Kickoff) via the service key; sent a broadcast (0 devices — nobody's on
  v1.17.0 yet, so no tokens registered; delivery begins as users move to the new build).
- **Docs + report.** Wrote proper READMEs (app/admin/website), `HANDOFF_29-07-2026.md`,
  `TEST_CASES_29-07-2026.md`, and a PDF progress report + the v1.17.0 APK in `reports/29-07-2026/`.
- **Attribution cleanup.** Rewrote git history in all three repos to strip AI/co-author trailers and
  force-pushed (`main` on all; `Gautam` on website); verified 0 remaining. Going forward commits carry
  no such trailer (see the standing preference).
- **Admin bonus.** Credited **6000 points** ("Special Bonus") to `glasgotra578@gmail.com` via the
  service-gated ledger (`/api/wallet/credit`, now accepts `email`); balance 100 → 6100.
- **User segregation (app vs website).** Admin **Customers** now lists website users; **FitBox App →
  Users** lists app users; a genuine dual-user shows in **both**.
  - Signals: app backend stamps `lastAppLoginAt` on any authenticated request (only the app calls it);
    the website stamps `lastWebLoginAt` when the request carries `X-Client: web` (website frontend sets
    it by default; the app doesn't send it, so its logins through the shared auth endpoint aren't
    miscounted).
  - Backfill/known data: `runs`/`territories`/`orders`/tokens are all empty for the current 17 test
    users, so there was no historical signal — Customers defaults to show any non-app-only account, and
    testers can be tagged via `POST /api/appmaint/tag {email, app, web}` (tagged `glasgotra578` as app).
- **Fix — website login broken by the new header.** `X-Client` triggered a CORS preflight that the
  website backend's `allowedHeaders` rejected → all logins (email + Google) failed with "network error".
  Added `X-Client` to the website CORS allowlist; verified the preflight now permits it. (App login was
  never affected — not a browser, doesn't send the header.)
- **Website wallet page.** New dedicated `/account/wallet` (full history table, filter, **CSV export**
  and **Save-as-PDF** via the browser print dialog — no new libraries). The account page now shows just
  the balance + last 3 transactions with a "View all" link, so the profile section no longer scrolls off.
- **Next:** on-device testing of v1.17.0 (background run, seasons, challenges, push) on a phone.

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
