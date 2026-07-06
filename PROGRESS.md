# FitBox App — Progress Log

A running development log. Newest entry on top. Weekly reports are added here each week.

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

### Next (weeks 1–2)
- Set up the Flutter frontend foundation (state management, navigation, folder structure, theme).
- Build first screens with mock data: login, home/dashboard (fitness stats), wallet.
- Wire the app to the live backend + shared database once the backend URL is available (~week 2).

### Blocked on / needed
- MongoDB Atlas access, `JWT_SECRET`, Google Maps API keys (see the access/keys doc).
- Live backend URL — expected from the website side by week 2.

### Cross-system (July, with Diwakar — he leaves end of July)
- Lock the shared wallet schema; build wallet end-to-end (earn in app → same balance → redeem at
  website checkout); add app-data section(s) to the admin portal.
