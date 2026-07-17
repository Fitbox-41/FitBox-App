# FitBox — Google Stitch prompts

Stitch designs best **one screen (or one short flow) at a time**. Paste the **STYLE BLOCK once at the
top of every screen prompt**, then add that screen's description underneath. Keeping the same tokens and
component language on every generation is what makes the screens feel like one real app.

> Tip: ask for **both a dark and a light** version of the hero screens (Dashboard, Wallet, Profile,
> Run). When you get one you like, send me its Stitch/Figma link and I'll rebuild it faithfully in
> Flutter for Android + iOS + Web.

---

## ⭐ STYLE BLOCK — prepend to every screen prompt

> Design a **premium mobile fitness app** called **FitBox** — a GPS run-tracking + territory-capture
> fitness game in the spirit of **Strava, Nike Run Club and Adidas Running**, but with the restraint,
> depth and polish of a **first-party Apple app** (think Apple Fitness / Fitness+ / Health). The feeling
> should be: *quiet, premium, physical, alive.*
>
> **Brand (from the FitBox logo):** the logo is a **dynamic, forward-leaning italic** wordmark — "Fit"
> in charcoal with **motion / speed streak lines**, "BOX" in bold red — so the whole design should feel
> like **motion and speed**: subtle forward-diagonal energy, speed-line accents, dynamic italic numerals
> for big stats. Core palette: **charcoal `#2E2E30`** surfaces + **signature red `#E31E24`** (with a
> deeper `#B3141A` for gradients) as the single energy accent.
>
> **Color discipline (very Apple):** mostly monochrome — charcoal/graphite surfaces, white/near-white
> type — and let **red be the only saturated color**, used sparingly for CTAs, progress rings, active
> tab, and "live" states. No rainbow of colors. Green `#19A463` only for positive money (credits),
> red-orange `#E5484D` for debits.
>
> **Backgrounds:** dark theme = deep vertical gradient `#1A1B21 → #0A0B0E` with one **soft red radial
> glow** bleeding in from a corner. Light theme = `#F2F4F8 → #E6E9F0` with a faint red glow. Both themes
> required.
>
> **Materials & glass (iOS-style):** frosted-glass cards that look like real **iOS system materials** —
> translucent, background-blurred, with a **1px hairline inner border**, ~22–28px corner radius, and a
> soft ambient shadow. Layer depth: content floats above the gradient; the **tab bar / nav bar is a
> floating frosted-glass bar** with vibrancy. Never flat gray boxes.
>
> **Typography:** **SF Pro**-style clean sans. Big, **bold rounded numerics** for stats (like the Apple
> Fitness activity numbers). Large-title headers that feel like iOS large titles. Tight, confident
> spacing on an 8pt grid with generous negative space.
>
> **Motion (describe it in the design notes for each screen):** everything eases with **spring / ease-out**
> physics, never linear. Numbers **count up**, progress **rings fill**, cards **stagger-fade-and-slide in**,
> the logo does a **hero shared-element transition** between screens, buttons have a **springy press**,
> sheets slide up as **rounded modal cards**, large titles **collapse on scroll**, and pull-to-refresh uses
> a **custom red indicator**. Motion should feel physical and smooth — Apple-grade, not flashy.
>
> **Platforms:** design **mobile-first**, but the same UI must **scale cleanly to tablet / desktop web**
> by centering a max-width column and letting the glass tab bar become a side rail on wide screens.

---

## Apple-feel non-negotiables (keep these true on every screen)
- One accent color (red). Restraint over decoration.
- Real translucency + blur + hairline borders — depth, not drop-shadow-on-white.
- Rounded, bold numerics for data; large collapsing titles for headers.
- Spring/ease-out motion; nothing snaps or fades linearly.
- Consistent components everywhere: **glass card, stat tile, red pill button, glass tab bar, progress ring.**
- Comfortable touch targets, generous padding, aligned to an 8pt grid.

---

## Screens to generate

### 1. Splash
Centered FitBox logo on a small white rounded "badge" floating over the dark gradient + red glow; a slim
red loading indicator below. Minimal, premium, still. (Logo animates out via hero transition into Login.)

### 2. Onboarding (3 slides)
Three swipeable full-bleed slides over the gradient, each with a bold headline, one line of copy, and a
simple line/glass illustration: "Track every run", "Capture territory as you move", "Earn points, spend
in-store". Page dots + a red "Get started" on the last slide, "Skip" top-right.

### 3. Login
Logo badge on top; a frosted glass card with "Welcome back", email + password glass fields, a "Forgot
password?" link, a full-width red "Log in" pill, an "or" divider, a "Continue with Google" button, and a
"Don't have an account? Sign up" row.

### 4. Sign up (2 steps)
- Step 1: logo badge + glass card with Full name, Email, Password, a red "Send verification code" button,
  a "Sign up with Google" option, "Already have an account? Log in".
- Step 2: a 6-digit **OTP** entry (large spaced digit boxes) with "Create account", "Resend code",
  "Change details".

### 5. Forgot / reset password
Step 1: email field + "Send code". Step 2: 6-digit OTP + new password + confirm + "Reset password".

### 6. Home / Dashboard — the hero screen
- Large collapsing title: "Hi, {name}" + a notifications bell.
- Big **glass card with an animated circular steps ring** (e.g. 7,432 / 10,000, 74%) — the number counts
  up and the ring fills. Dynamic italic numerals.
- A row of 3 glass stat tiles: **calories (kcal)**, **distance (km)**, **active minutes** (icon + big number).
- A "This week" glass card with a **7-day bar chart** (today's bar red, others muted).
- A prominent red **"Start a run"** button (feels like a primary action / FAB).
- Optional flourishes: a "🔥 5-day streak" chip, a "Territory this week" teaser card with a mini map.

### 7. Start / Record run (live tracking)
Full-screen **map** with the live route drawn in red; a translucent **glass panel** floating over the map
with live **duration, distance, current pace, calories** in big numerals; large circular **Start / Pause /
Stop** controls; a GPS-lock / 3-2-1 countdown state. Apple-Fitness-workout-like.

### 8. Run summary / detail
Map with the completed route at top; headline stats (distance, time, avg pace, calories, elevation); a
**pace / splits bar chart** (per-km); "Share" and "Save" actions; a **"+150 pts earned"** banner that
feels celebratory.

### 9. Activity / History
Scrollable list of past runs as glass cards — each with title, date, distance, time, pace, calories, and a
tiny route thumbnail. Filter chips (All / Runs / Walks). A weekly/monthly totals header that collapses on scroll.

### 10. Territory map — the game
A **map** showing the user's captured territory as **red translucent polygons** vs rivals' muted areas. A
glass overlay with "Your area this week", rank, and a "Claim more by running" hint. A weekly-reset countdown chip.

### 11. Leaderboard
Weekly leaderboard as a glass list: rank, avatar, name, territory area / points. A **podium for the top 3**
at the top; the current user's row highlighted in red.

### 12. Wallet
A **glowing red gradient balance card** (big points number that counts up; caption "Earn by staying active
· spend at checkout"), then a glass card list of transactions — credit (green +) / debit (red −), with
description, date and signed amount.

### 13. Goals & achievements
Editable goals (daily steps, weekly distance, weekly runs) each shown as a **progress ring**; a grid of
**badges/achievements** (locked = frosted/greyed, unlocked = red-accented); a small **streak calendar**.

### 14. Profile
Glass profile header (avatar, name, email); an **Appearance** control (System / Light / Dark as an
equal-thirds segmented pill, selected = red); a menu (Leaderboard, Goals, Set/Change password, Help); a
"Log out" button.

### 15. Settings
Grouped glass lists (iOS Settings style): Account, Appearance (theme), Units (km / mi), Notifications
(toggles), Connected accounts (Google), Privacy (health / location), About.

### 16. Notifications feed
Glass list of notifications, each with icon + text + time: workout reminders, "you've been overtaken in
{area}", weekly results, "points credited", achievement unlocked.

---

## How to drive Stitch (workflow)
1. Paste the **STYLE BLOCK**, then **one screen's** description. Generate.
2. Regenerate a couple of times; keep the best. For the hero screens, also ask for the **opposite theme**.
3. Reuse the exact component words ("glass card", "red pill button", "progress ring", "glass tab bar") so
   the system stays consistent.
4. Send me the links to the ones you love → I implement them in Flutter across Android + iOS + Web,
   keeping the glassmorphism + motion.
