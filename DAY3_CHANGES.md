# Day 3 Feature Rollout — What Changed

Implements all 4 Day 3 features: **Breathing & Prayer Exercise**, **Sleep
Prayer (Night Mode)**, **Topical Scripture Search**, and **AI Prayer
Writer** — across backend, Flutter mobile, and the React web app. Same
approach as Days 1–2: additions only, existing colors/screens untouched.

## 1. Breathing & Prayer Exercise (Free)
No backend needed, as planned. An animated 4-7-8 breathing screen (4s
inhale, 7s hold, 8s exhale) with a rotating short prayer line and a cycle
counter. Entry point: a new tile on the **Wellness** screen (mobile) /
page (web), right under Guided Affirmations.

## 2. Sleep Prayer / Night Mode (Free)
No backend needed. A dark, minimal bedtime screen that rotates through 4
calming night prayers (with a verse each) every 14 seconds. Same entry
point area as Breathing Exercise.

## 3. Topical Scripture Search (Free, 3/day — unlimited for Standard/Premium)
- **Backend**: `POST /api/scripture-search` — takes a topic/feeling, asks
  the same OpenAI model already used for AI chat to return 4–6 real,
  relevant Bible verses as structured JSON (reference, verse text, a
  one-line "why it fits" note). `GET /api/scripture-search/status` reports
  remaining free searches without consuming one.
- Free users are capped at 3 searches/day (tracked the same way the
  existing AI ad-unlock daily limit works); Standard and Premium users get
  unlimited searches — this is now one of the first features that actually
  uses the new Standard tier for something.
- **Mobile & Web**: a search screen/modal with topic input, quick-pick
  suggestion chips (fear, forgiveness, waiting on God, provision, healing),
  and a card per result. Reachable from the AI tab.

## 4. AI Prayer Writer (Premium only)
- **Backend**: `POST /api/ai-prayer-writer` — describe a situation, get
  back a personalized prayer (150–220 words) plus one real supporting Bible
  verse, generated the same way. Gated to Premium only — free and Standard
  users get a clear 403 with an upgrade prompt. Every generated prayer is
  saved as a normal `Prayer` record, so it shows up in the **Answered
  Prayer Wall** from Day 2 and can be marked answered later.
- **Mobile & Web**: a description box → "Write My Prayer" → generated
  prayer + verse. Non-Premium users tapping the entry point see the
  existing upgrade sheet/message instead of a broken feature.

## Shared backend groundwork
- New `src/services/openaiClient.js` — the OpenAI request/response
  plumbing extracted so these two new endpoints don't duplicate it.
  **`aiChat.js` itself was not touched** — it keeps its own copy, so your
  working AI chat feature has zero risk of regression from this change.
- New `dailyUsageFor()` helper in `services/monetization.js` — a generic
  version of the existing daily-usage-counter pattern, reused for the
  scripture search limit and available for future daily-limited features.

## Files touched
```
backend .../src/services/openaiClient.js     (new, shared — aiChat.js untouched)
backend .../src/services/monetization.js     (dailyUsageFor helper)
backend .../src/routes/scriptureSearch.js    (new)
backend .../src/routes/aiPrayerWriter.js     (new)
backend .../src/index.js                     (mount new routes)
lib/services/api_service.dart
lib/screens/main/wellness_screen.dart        (entry tiles)
lib/screens/main/breathing_exercise_screen.dart  (new)
lib/screens/main/sleep_prayer_screen.dart        (new)
lib/screens/main/ai_screen.dart              (entry buttons)
lib/screens/main/scripture_search_screen.dart    (new)
lib/screens/main/ai_prayer_writer_screen.dart    (new)
revivespring-react/src/App.tsx               (all 4 features)
revivespring-react/src/styles.css
```

## Nothing new needed in Google Play Console
These 4 features don't touch billing — Topical Scripture Search and AI
Prayer Writer are gated purely by your existing plan tiers (`free` /
`standard` / `premium`), no new products required.
