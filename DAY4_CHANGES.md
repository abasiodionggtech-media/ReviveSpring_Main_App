# Day 4 Feature Rollout — What Changed

Implements all 4 Day 4 features: **30-Day Prayer Challenges**, **Fasting
Tracker**, **Bible Reading Plan**, and **Faith Milestones & Badges** —
across backend, Flutter mobile, and the React web app. Same rule as every
prior day: additions only, nothing existing was altered or restyled.

## ⚠️ Please read first: a discrepancy I found

While building today, I noticed the **Bible Version feature** (NIV/KJV/
NLT/ESV picker) from a couple of sessions ago is no longer present
anywhere in the codebase — not in the backend schema, not in Flutter, not
in React. I don't have full visibility into why (possibly something
related to how this long-running session persists state between messages),
but I want to flag it honestly rather than let you discover it later.
**Everything else from every prior day — onboarding, subscriptions, Day
1–3 features, the AI model/persona change — is present and intact.** Let
me know and I'll rebuild the Bible Version feature; it's a contained piece
of work.

## 1. 30-Day Prayer Challenges (Free)
- **Backend**: `Challenge` (admin-managed content) + `ChallengeEnrollment`
  (per-user progress) tables. Routes: `GET /api/challenges` (list with
  enrollment status), `POST /api/challenges/:id/join`,
  `POST /api/challenges/:id/check-in` (once per day). Seeded with 3
  challenges: 7-Day Gratitude, 21-Day Peace, 30-Day Closer to God.
- **Mobile & Web**: a challenge browser with a progress bar per challenge,
  "Join" and "Check In Today" actions, and a celebration message on
  completion. Reachable from Daily Goals under a new "Structured Growth"
  section.

## 2. Fasting Tracker (Free)
- **Backend**: `Fast` table (type, goal hours, start/end, status). Routes:
  `GET /api/fasts` (history), `GET /api/fasts/active`,
  `POST /api/fasts/start`, `POST /api/fasts/:id/end` (completed or broken).
  Only one active fast at a time per user.
- **Mobile & Web**: pick a fast type (Water, Daniel, Partial, Full), a
  live running timer once started, and "Break Fast" / "Complete" actions,
  plus a history list below.

## 3. Bible Reading Plan (Free)
- **Backend**: `ReadingPlan` (admin content, with each day's reference
  stored as JSON — no verse text, just references, to stay copyright-safe)
  + `ReadingPlanProgress` (per-user). Routes mirror the challenges pattern:
  list, start, check-off. Seeded with 2 plans: "Psalms of Comfort" (7
  days) and "The Life of Jesus" (5 days, Gospel of Luke).
- **Mobile & Web**: plan browser showing today's specific reading
  reference and title, a progress bar, and a check-off button.

## 4. Faith Milestones & Badges (Free)
- **Backend**: `Milestone` (admin-defined badge criteria) +
  `UserMilestone` (earned badges). A lightweight **checker service**
  (`src/services/milestones.js`) compares a user's real stats — prayer
  count, streak, goals completed, journal entries, fasts completed,
  challenges finished, reading plans finished — against each milestone's
  threshold and awards new badges. `POST /api/milestones/check` runs the
  check (client calls this on badge-gallery open); `GET /api/milestones`
  just reads current state without awarding.
  - **Design choice**: rather than hooking this into every existing route
    that could trigger a badge (prayers, goals, journal, fasts,
    challenges), the check runs on-demand from the client. This kept the
    feature fully additive — zero existing route files needed to change,
    zero regression risk to already-working features.
  - Seeded with 10 starter badges (first prayer, 25/100 prayers, 7/30-day
    streaks, 30 goals, 10 journal entries, first fast, first challenge,
    first reading plan).
- **Mobile & Web**: a badge gallery (grid on mobile, cards on web) showing
  locked vs. earned badges with a progress bar toward each locked one, and
  a celebratory toast/alert when a new badge is earned. Reachable from the
  Profile screen.

## Files touched
```
backend .../prisma/schema.prisma            (7 new models total)
backend .../src/routes/challenges.js        (new)
backend .../src/routes/fasts.js             (new)
backend .../src/routes/readingPlans.js      (new)
backend .../src/routes/milestones.js        (new)
backend .../src/services/milestones.js      (new — badge checker)
backend .../src/index.js                    (mount new routes)
backend .../src/config/seed.js              (challenges, reading plans, milestones)
lib/services/api_service.dart
lib/screens/main/goals_screen.dart          (Structured Growth entry tiles)
lib/screens/main/challenges_screen.dart     (new)
lib/screens/main/fasting_tracker_screen.dart (new)
lib/screens/main/reading_plans_screen.dart  (new)
lib/screens/main/milestones_screen.dart     (new)
lib/screens/main/profile_screen.dart        (Milestones entry)
revivespring-react/src/App.tsx              (all 4 features)
revivespring-react/src/styles.css
```
