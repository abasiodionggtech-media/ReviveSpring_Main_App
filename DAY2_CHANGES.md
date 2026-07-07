# Day 2 Feature Rollout — What Changed

Implements the 3 Day 2 features: **Verse of the Moment**, **Prophetic
Declarations**, and **Answered Prayer Wall** — across backend, Flutter
mobile, and the React web app. Same rule as Day 1: no existing UI, colors,
or screens were removed or restyled, only additions.

## ⚠️ No manual migration step needed
As covered before, your `npm start` already runs `prisma db push --accept-data-loss`
on boot (no `prisma/migrations` folder exists yet), so the new `Declaration`
model and the new `Prayer` fields (`is_answered`, `testimony`, `answered_at`)
apply themselves automatically the next time the server restarts.

One extra step **for Day 2 only**: run the seeder once so there's content to
show (`node src/config/seed.js` from `backend-reset-work/revivespring-main/revivespring-main`,
or just the "Prophetic declarations seeded" block if you don't want to
reseed everything else). Without seeded declarations, the Declaration card
simply won't show anything — no error, just empty.

## 1. Verse of the Moment
- **Backend**: `GET /api/daily-verse/random` — a non-deterministic pick
  from the existing `daily_verses` table (reuses Day 1's verse bank).
- **Mobile**: `VerseOfMomentDialog` — a full-screen tap-to-reveal moment
  (button on Home: "Verse of the Moment — tap for a fresh word").
- **Web**: `VerseOfMomentModal`, same tap-anywhere-for-another-verse pattern.

*Note*: the plan mentioned "shake/tap gesture." I implemented the tap
gesture only — I didn't add a shake/accelerometer package since that
requires native platform wiring I can't verify without a real device and a
network connection to fetch/test the package. Tap works today everywhere
and needs zero new dependencies; happy to wire up shake detection in a
follow-up if you want it.

## 2. Prophetic Declarations
- **Backend**: new `Declaration` model (`declarations` table, admin-managed,
  seeded with 7 starter declarations), `/api/declarations` routes
  (`GET /today`, `POST /confirm`). Streak state lives in
  `User.onboardingData.declarationStreak` (no second table, per the plan).
- **Mobile**: `DeclarationCard` on Home — shows today's declaration and an
  "I declare this over my life" button with a streak counter.
- **Web**: `DeclarationCard` component, same behavior.

## 3. Answered Prayer Wall
- **Backend**: `Prayer` model gained `isAnswered`, `testimony`, `answeredAt`.
  `GET /api/prayers?answered=true` filters to answered-only.
  `PATCH /api/prayers/:id/answered` marks a prayer answered with a testimony.
- **Mobile & Web**: the existing **Journal** screen (already labeled
  "Prayer Journal") now has a tab toggle — "My Entries" / "Answered Prayer
  Wall". The wall shows answered prayers with testimonies, plus a short list
  of unanswered prayers with an "Answered" button that opens a small
  testimony dialog.

## Files touched (new since Day 1)
```
backend .../prisma/schema.prisma              (Declaration model, Prayer fields)
backend .../src/index.js                      (mount declarations route)
backend .../src/routes/dailyVerse.js          (/random endpoint)
backend .../src/routes/prayers.js             (answered filter + PATCH)
backend .../src/routes/declarations.js        (new)
backend .../src/config/seed.js                (declarations seed data)
lib/services/api_service.dart
lib/core/app_controller.dart
lib/screens/main/home_screen.dart
lib/screens/main/journal_screen.dart
lib/widgets/declaration_card.dart             (new)
lib/widgets/verse_of_moment_dialog.dart       (new)
revivespring-react/src/App.tsx
revivespring-react/src/styles.css
```
