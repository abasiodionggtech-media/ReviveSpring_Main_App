# Day 1 Feature Rollout — What Changed

Implements the 3 Day 1 features from the rollout plan: **Mood Check-In (Daily)**,
**Daily Manna (Daily Reward)**, and **Prayer Streaks w/ Grace Period** — across
backend, Flutter mobile, and the React web app. No existing UI, colors, or
screens were removed or restyled; everything new reuses the app's existing
design system (AppColors / GlassPanel on mobile, Panel/.stat/.mood-modal on web).

## ⚠️ One manual step required (backend)

The Prisma schema changed (new `MoodLog` model + 2 new `Analytics` columns).
Because this container has no database connection, I could not generate the
migration. Before deploying, run, from `backend-reset-work/revivespring-main/revivespring-main`:

```
npx prisma migrate dev --name day1_mood_manna_streak_grace
```

This will create the `mood_logs` table and add `grace_period_used` /
`grace_used_on_date` columns to `analytics`. Everything else runs as-is.

## 1. Mood Check-In (Daily)
- **Backend**: new `MoodLog` model (`mood_logs` table, one row per user per day),
  routes at `src/routes/moodCheckIn.js` mounted at `/api/mood-checkin`
  (`GET /today`, `POST /`, `GET /history`).
- **Mobile**: `DailyCheckInModal` widget shows once per app open if the user
  hasn't checked in yet today (reuses the existing `moods` list/colors).
- **Web**: same modal pattern (`DailyCheckInModal` in `App.tsx`), shown once
  per load if not checked in.

## 2. Daily Manna (Daily Reward)
- **Backend**: state stored in `User.onboardingData.dailyManna` (no new
  table, per the plan) — `src/routes/dailyManna.js` at `/api/daily-manna`
  (`GET /status`, `POST /claim`). Rotates a verse + blessing daily.
- **Mobile**: `DailyMannaCard` — animated gift icon that reveals the day's
  verse/blessing on tap, shown on Home under the stats grid.
- **Web**: `DailyMannaCard` component, same behavior, styled with new
  `.manna-card` / `.manna-gift-button` CSS.

## 3. Prayer Streaks w/ Grace Period
- **Backend**: `updateStreak()` in `src/routes/goals.js` now forgives exactly
  one missed day per streak (tracked via `Analytics.gracePeriodUsed`).
  `analytics.js` now also returns `gracePeriodAvailable` and `lastActiveDate`.
  New cron-style job `src/jobs/streakGraceCheck.js` (runs hourly) sends an
  in-app notification to users currently sitting in their grace day.
- **Mobile & Web**: Streak stat tile shows "Streak · grace day" / "Streak
  (grace day)" when the user is in their forgiven day, computed client-side
  from `lastActiveDate` + `gracePeriodAvailable`.

## Files touched
```
backend .../prisma/schema.prisma
backend .../src/index.js
backend .../src/routes/goals.js
backend .../src/routes/analytics.js
backend .../src/routes/moodCheckIn.js        (new)
backend .../src/routes/dailyManna.js         (new)
backend .../src/jobs/streakGraceCheck.js     (new)
lib/services/api_service.dart
lib/core/app_controller.dart
lib/screens/main/home_screen.dart
lib/widgets/daily_checkin_modal.dart         (new)
lib/widgets/daily_manna_card.dart            (new)
revivespring-react/src/App.tsx
revivespring-react/src/styles.css
```
