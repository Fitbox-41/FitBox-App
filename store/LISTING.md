# Play Store listing — FitBox

Everything the Console asks for, ready to paste. Assets are in this folder.

## App details
- **App name:** FitBox
- **Package:** `com.fitboxsports.app`
- **Category:** Health & Fitness
- **Contact email:** fitboxsports01@gmail.com
- **Privacy policy:** https://www.fitboxsports.in/privacy

## Short description (80 char max)
> Run, claim real territory on the map, earn points to spend at FitBox Sports.

## Full description
> **Turn every run into ground you own.**
>
> FitBox tracks your runs with GPS and turns the route into territory on a shared
> map. The ground you cover becomes yours — and stays yours, until another runner
> covers it first. Run a loop and you claim everything inside it.
>
> **Earn as you run.** Every saved run credits points immediately, and the top
> twenty runners by ground claimed each week share a weekly prize. Points are spent
> on real equipment at the FitBox Sports store.
>
> **What's inside**
> • GPS run tracking — route, distance, pace, calories and steps
> • A shared territory map — see who holds what, and take it
> • A daily step goal you set yourself
> • Challenges with point rewards
> • A weekly leaderboard and a weekly prize
> • Points redeemable at the FitBox Sports shop
> • Optional daily reminder to get your run in
>
> FitBox records only the activity you track in the app. It does not read from Apple
> Health, Health Connect or any other health app, and it does not count steps taken
> outside a tracked run.
>
> FitBox Sports, Jalandhar, Punjab.

## Assets in this folder
| File | Use |
|---|---|
| `play-icon-512.png` | High-res icon (512×512, 32-bit PNG). Generated from the launcher icon, so the store and the home screen can't drift apart |
| `play-feature-graphic-1024x500.png` | Feature graphic (1024×500, no alpha) |
| `screenshots/` | Phone screenshots, captured from the release build |

## Declarations the Console will ask for
- **Data safety** — collected: location (app functionality), personal info (name,
  email — account), fitness/activity (app functionality). All linked to the user,
  none sold, deletion available in-app and at the privacy-policy URL.
- **Foreground service** — `FOREGROUND_SERVICE_LOCATION`. Justification: the run
  keeps recording GPS while the screen is off or the app is backgrounded. Shown
  to the user as an ongoing notification for the duration of the run only.
- **Background location** — **not requested**, so no declaration form or demo
  video is required.
- **Account deletion** — in-app at Settings → Account → Delete account, and on the
  web at https://www.fitboxsports.in/account.
- **Ads** — none. **In-app purchases** — none.
- **Content rating** — questionnaire: no objectionable content.
- **App access** — login required. Supply a demo account for the reviewer.
- **Target audience** — 18+.

## Before submitting
1. Register the developer account as an **organisation** (FitBox Sports), not a
   personal account: new personal accounts must run a closed test with 12 testers
   for 14 days before they can publish to production. Organisations are exempt.
2. Upload `build/app/outputs/bundle/release/app-release.aab` (not the APK).
3. Complete the declarations above.
4. Screenshots: Gautam is supplying these once the owner signs off the final build.
