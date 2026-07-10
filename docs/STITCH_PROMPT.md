# FitBox — Google Stitch prompts

Stitch works best one screen (or short flow) at a time. **Paste the STYLE BLOCK once
at the top of each screen prompt**, then the screen's description. Keep the brand tokens
identical across every generation so the screens feel like one app.

---

## ⭐ STYLE BLOCK (prepend to every screen prompt)

> Design a **premium mobile fitness app** called **FitBox** — a blend of **Strava, Nike Run Club and
> Adidas Running**, with an **Apple-style** aesthetic and **glassmorphism**.
>
> **Brand:** charcoal `#2E2E30` + signature red `#E31E24`, on a **deep dark gradient background**
> (`#1A1B21` → `#0A0B0E`) with a soft red glow. Also provide a **light** variant (gradient `#F2F4F8` →
> `#E6E9F0`). White/near-white text on dark; near-black on light.
>
> **Look & feel:** frosted-glass cards (translucent, blurred, 1px hairline border, ~22px corner radius,
> soft shadow), generous spacing, large rounded corners, SF-Pro-like clean typography, bold numeric
> stats. Red is the accent for CTAs, progress rings and active states. Tab bar / nav is a **frosted
> glass bar**. Subtle depth, no flat gray boxes.
>
> **Motion (note in the design):** count-up numbers, animated progress rings, staggered card
> fade/slide-in, hero logo transition, springy button presses.
>
> **Platforms:** the same UI must work on **phone, and scale cleanly to tablet/desktop web** (center a
> max-width column on large screens). Design mobile-first.

---

## Screens to generate

### 1. Splash
Centered FitBox logo on a small white rounded "badge" over the dark gradient with the red glow; a slim
red loading indicator below. Minimal, premium.

### 2. Login
Logo badge on top; a frosted glass card with "Welcome back", email + password fields (rounded, glass
inputs), a "Forgot password?" link, a full-width red "Log in" button, an "or" divider, a "Continue with
Google" button, and a "Don't have an account? Sign up" row.

### 3. Sign up (2 steps)
- Step 1: logo badge + glass card with Full name, Email, Password, a red "Send verification code"
  button, a "Sign up with Google" option, and "Already have an account? Log in".
- Step 2: a 6-digit **OTP** entry (large spaced digits) with "Create account", "Resend code", and
  "Change details".

### 4. Forgot / reset password
Step 1: email field + "Send code". Step 2: 6-digit OTP + new password + confirm + "Reset password".

### 5. Home / Dashboard  (the hero screen)
- Top bar: "Welcome back / Hi, {name}" + notifications bell.
- Big **glass card with an animated circular steps ring** (e.g. 7,432 / 10,000, 74%) — number counts up.
- A row of 3 glass stat tiles: **calories (kcal)**, **distance (km)**, **active minutes** (icons + big numbers).
- "This week" glass card with a **7-day bar chart** (today highlighted red).
- A prominent red **"Start a run"** button/FAB.
- Optional: streak chip ("🔥 5-day streak"), a "Territory this week" teaser card.

### 6. Start / Record run (live tracking)
Full-screen **map** with the live route drawn in red; a translucent glass panel over the map showing
live **duration, distance, current pace, calories**; big **Start / Pause / Stop** controls; a GPS/countdown
state. Apple-Fitness-like.

### 7. Run summary / detail
Map with the completed route; headline stats (distance, time, avg pace, calories, elevation); a **pace/
splits chart** (per-km); "share" and "save" actions; points earned banner ("+150 pts").

### 8. Activity / History
A scrollable list of past runs as glass cards — each with title, date, distance, time, pace, calories,
and a tiny route thumbnail. Filter chips (All / Runs / Walks). Weekly/monthly totals header.

### 9. Territory map (the game)
A **map** showing the user's captured territory (red translucent polygons) vs others' (muted). A glass
overlay with "your area this week", rank, and a "claim by running" hint. Weekly reset countdown.

### 10. Leaderboard
Weekly leaderboard as a glass list: rank, avatar, name, territory area / points; the current user's row
highlighted red; podium (top 3) at the top.

### 11. Wallet
A **glowing red gradient balance card** (points balance, "earn by staying active · spend at checkout"),
then a glass card list of transactions (credit green / debit red, description, date, signed amount).

### 12. Goals & achievements
Editable goals (daily steps, weekly distance) with progress rings; a grid of **badges/achievements**
(locked/unlocked); streak calendar.

### 13. Profile
Glass profile header (avatar, name, email); an **Appearance** control (System / Light / Dark segmented,
equal thirds); menu (Leaderboard, Goals, Set/change password, Help); a "Log out" button.

### 14. Settings
Sections: Account, Appearance (theme), Units (km/mi), Notifications toggles, Connected accounts
(Google), Privacy (health/location), About.

### 15. Notifications feed
Glass list of notifications: workout reminders, "you've been overtaken", weekly results, points credited
— each with icon, text, time.

---

## Tips
- Ask Stitch for **both dark and light** versions of key screens (dashboard, wallet, profile).
- Keep the **same components** (glass card, stat tile, red button, glass tab bar) across screens.
- When you have a screen you like, share its **Stitch/Figma link** with me and I'll rebuild it faithfully
  in Flutter for Android + iOS + Web.
