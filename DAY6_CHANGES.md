# Day 6 Feature Rollout — What Changed

Implements all 4 Day 6 features: **Prayer Room (Ambient)**, **Worship
Mode**, **Weekly Spiritual Review**, and **Grief & Crisis Support Mode** —
across backend, Flutter mobile, and the React web app. Same rule as every
prior day: additions only.

## 1. Prayer Room (Ambient) — Premium
No backend needed, as planned. An immersive full-screen space: pick 5, 10,
15, or 20 minutes, then sit with a slow pulsing glow and a rotating prayer
prompt until the timer ends on "Amen."

**One honest scoping note**: the spec mentions "audio UI." This app has no
audio-player package or bundled sound assets, and I didn't want to bolt on
a new native dependency (with its own platform config and testing needs)
just to fake a feature. So Prayer Room is visual/timer-only for now — no
actual ambient sound. If you want real audio, that's a follow-up: add an
audio package (e.g. `just_audio`), a few licensed ambient tracks as assets,
and I can wire it in.

## 2. Worship Mode — Premium
- **Backend**: new `WorshipTrack` table (admin-managed) + `GET
  /api/worship-tracks` (Premium-gated). Seeded with 5 real, verified
  worship songs (Way Maker, 10,000 Reasons, Oceans, Goodness of God, What
  A Beautiful Name) — I looked up each one's official YouTube link rather
  than guessing, so they actually work.
- **Mobile & Web**: a playlist list — tapping a track opens it in YouTube
  (or Spotify, if you add Spotify tracks via the admin panel) using the
  app's existing link-opening mechanism. No in-app audio player needed,
  matching the plan's "Integrate YouTube/Spotify links" note.

## 3. Weekly Spiritual Review — Free
- **Backend**: new `WeeklyReview` table. `GET /api/weekly-review` computes
  the most recently completed Monday-Sunday week, and generates (once,
  lazily) a short AI reflection on that week's prayers/journal/goals/
  streak — cached so it's not regenerated on every visit.
  `POST /api/weekly-review/reflection` saves the user's own written
  thoughts. A new daily cron job (`weeklyReviewJob.js`) pre-generates this
  for recently-active users once the week's Sunday has arrived, so it's
  usually already waiting — satisfying "runs every Sunday automatically."
- **Mobile & Web**: shows the week's AI summary, quick stats, and a text
  box for the user's own reflection.

## 4. Grief & Crisis Support Mode — Free
- **Backend**: there was actually no public endpoint at all for the
  existing (admin-only) `MentalHealthContent` table before this — so this
  genuinely extends it, per the plan, with zero new tables. New
  `GET /api/mental-health-content` (general, filterable by category) and
  `GET /api/mental-health-content/crisis-support` (always free, never
  Premium-gated) which combines grief-category content with **crisis
  hotline resources I verified are current**: the 988 Suicide & Crisis
  Lifeline and Crisis Text Line (text HOME to 741741), both US-based, with
  a note to search local resources if outside the US.
- **Mobile & Web**: a dedicated, always-accessible section with the crisis
  resources shown first, followed by grief-focused reflections and
  prayers.

## Files touched
```
backend .../prisma/schema.prisma          (WorshipTrack, WeeklyReview)
backend .../src/routes/worship.js         (new)
backend .../src/routes/weeklyReview.js    (new)
backend .../src/routes/mentalHealth.js    (new — first public route for existing content)
backend .../src/jobs/weeklyReviewJob.js   (new)
backend .../src/index.js                  (mount routes + cron)
backend .../src/config/seed.js            (worship tracks, grief content)
lib/services/api_service.dart
lib/screens/main/wellness_screen.dart     (4 new entry tiles)
lib/screens/main/prayer_room_screen.dart  (new)
lib/screens/main/worship_mode_screen.dart (new)
lib/screens/main/weekly_review_screen.dart (new)
lib/screens/main/grief_crisis_support_screen.dart (new)
revivespring-react/src/App.tsx            (all 4 features + WellnessScreen now takes `user`)
revivespring-react/src/styles.css
```

## Nothing new needed in Google Play Console
All 4 features are gated by your existing plan tiers — no new billing
products required.
