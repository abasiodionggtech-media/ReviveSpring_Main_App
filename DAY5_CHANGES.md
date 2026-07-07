# Day 5 Feature Rollout — What Changed

Implements all 5 Day 5 features: **Scripture Memory Cards**, **AI
Spiritual Companion**, **AI Sermon Summarizer**, **AI Dream/Vision
Journal**, and **Spiritual Growth Score** — across backend, Flutter
mobile, and the React web app. Same rule as every prior day: additions
only, nothing existing was altered.

## 1. Scripture Memory Cards (Free)
- **Backend**: `MemoryCard` (admin content bank, 7 verses seeded) +
  `MemoryCardProgress` (per-user: review count, last reviewed date, quiz
  attempts, mastered flag). Routes: `GET /api/memory-cards`,
  `POST /:id/add`, `POST /:id/review` (flip/review, once per day),
  `POST /:id/quiz` (self-reported recall check — unlocked automatically 7
  days after adding a card).
- **Mobile & Web**: add a card, flip it to reveal the verse, mark it
  reviewed daily; after 7 days a "Take Quiz" button unlocks where the user
  confirms whether they recalled it, marking it mastered on success.
  Reachable from Daily Goals → Structured Growth.

## 2. AI Spiritual Companion (Premium)
- **Backend**: new `src/routes/aiCompanion.js` — a **single persistent
  chat thread per user** (not multi-session like AI Chat), reusing the
  existing `AiConversation` table under a dedicated session id. Before
  each reply, it pulls the user's last 7 mood check-ins and last 5 prayer
  topics and folds that into the system prompt so responses feel aware of
  their recent journey — without ever reciting that data back verbatim.
  Same prayer-only response format and GPT-5.4 Nano model as the rest of
  your AI features. `aiChat.js` itself was not touched.
- **Mobile & Web**: a dedicated chat screen/modal, Premium-gated with the
  existing upgrade sheet.

## 3. AI Sermon Summarizer (Premium)
- **Backend**: `POST /api/ai-sermon-summarizer` — paste sermon notes or a
  rough transcript, get back a faithful summary, key points, and a
  **3-day application plan** (title + one concrete action per day), as
  structured JSON.
- **Mobile & Web**: paste box → summary, key points list, and 3 day cards.

## 4. AI Dream/Vision Journal (Premium)
- **Backend**: extends the existing `JournalEntry` table (no new table, as
  planned) — added one optional column, `aiInterpretation`, and tags dream
  entries with `"dream"` so they're filterable without touching
  `journal.js`. `POST /api/dream-journal` saves the entry and generates a
  careful, non-prophetic spiritual reflection (deliberately worded to
  never claim certainty — dreams are sensitive territory).
- **Mobile & Web**: describe a dream, get a reflection, see past entries
  with their reflections underneath.

## 5. Spiritual Growth Score (Free)
- **Backend**: `GET /api/growth-score` — a read-only aggregate combining
  data from every feature built so far (prayers, streak, goals, journal,
  fasts, challenges, reading plans, memory cards mastered) into a
  weighted 0-100 score across 5 categories: Prayer (30%), Consistency
  (25%), Scripture Engagement (20%), Growth Actions (15%), Reflection
  (10%). No new table — it's purely computed from existing records.
- **Mobile & Web**: a new dashboard widget on Home showing the overall
  ring/percentage plus a progress bar per category.

## Files touched
```
backend .../prisma/schema.prisma          (MemoryCard, MemoryCardProgress, JournalEntry.aiInterpretation)
backend .../src/routes/memoryCards.js     (new)
backend .../src/routes/aiCompanion.js     (new — aiChat.js untouched)
backend .../src/routes/aiSermonSummarizer.js (new)
backend .../src/routes/dreamJournal.js    (new)
backend .../src/routes/growthScore.js     (new)
backend .../src/index.js                  (mount new routes)
backend .../src/config/seed.js            (memory cards seed)
lib/services/api_service.dart
lib/core/app_controller.dart              (growthScore fetch)
lib/screens/main/goals_screen.dart        (Memory Cards entry tile)
lib/screens/main/memory_cards_screen.dart (new)
lib/screens/main/ai_screen.dart           (3 new entry points)
lib/screens/main/ai_companion_screen.dart (new)
lib/screens/main/sermon_summarizer_screen.dart (new)
lib/screens/main/dream_journal_screen.dart (new)
lib/screens/main/home_screen.dart         (Growth Score widget)
lib/widgets/growth_score_card.dart        (new)
revivespring-react/src/App.tsx            (all 5 features)
revivespring-react/src/styles.css
```

## Nothing new needed in Google Play Console
All 5 features are gated by your existing plan tiers — no new billing
products required.
