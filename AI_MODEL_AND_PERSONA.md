# AI Model Switch + Persona/Prayer Constraint

## Model
All three AI endpoints (AI Chat Companion, Topical Scripture Search, AI
Prayer Writer) now default to **GPT-5.4 Nano** (`gpt-5.4-nano`) instead of
full GPT-5.4. This is controlled by the `OPENAI_MODEL` environment
variable — if it's set on your server, that value still wins; the code
change only affects what's used when that variable is absent.

Expect noticeably lower per-response cost. If you ever find Nano's output
feels too thin for a particular endpoint, the fix is a one-line env var
change (e.g. set `OPENAI_MODEL=gpt-5.4-mini`) — no code redeploy needed.

## Persona + response constraint (AI Chat Companion)
Rewrote the system prompt in `aiChat.js`:
- **Persona**: "The ReviveSpring Prayer Companion" — explicitly framed as a
  supporter of the app, not a generic AI assistant, in both English and
  French versions of the prompt.
- **Mandatory format**: no matter what's asked, the entire response must
  now be a prayer, first person, addressed to God. Any factual answer
  (about the Bible or the app) has to be woven *into* the prayer rather
  than stated separately — the model is instructed it may never break out
  of that format.
- **Conciseness**: response length cut from ~200–400 words to **80–150
  words**, and `max_output_tokens` reduced from 900 → 350 to enforce it.
  The instruction also explicitly says to "get straight to the point."
- Even the hard-coded fallback messages (used only if the API call fails
  outright) were rewritten as short prayers, so the app never breaks
  format even on an error.

## AI Prayer Writer
Already prayer-shaped by design, so this one needed less change: added the
same "ReviveSpring Prayer Writer" persona framing, tightened word count
from 150–220 to **100–160 words**, and lowered `max_output_tokens`
accordingly (600 → 450).

## Topical Scripture Search
This endpoint's job is to return verses, not a prayer — so instead of
forcing the whole response into prayer form (which would make the verse
list unusable), I added a **`closingPrayer`** field to the JSON contract:
a short (40–70 word) prayer that ties the returned verses back to exactly
what the user searched for. Both apps now show it under the verse results,
labeled "A prayer with these verses." The prompt also now explicitly
frames the model as the ReviveSpring Prayer Companion and instructs it to
stay tightly on the user's specific topic rather than returning generic
verses.

## Files touched
```
backend .../src/routes/aiChat.js           (model, persona, prayer-only format, shorter)
backend .../src/routes/aiPrayerWriter.js   (model, persona, tighter word count)
backend .../src/routes/scriptureSearch.js  (model, persona, new closingPrayer field)
lib/screens/main/scripture_search_screen.dart   (show closing prayer)
revivespring-react/src/App.tsx                  (show closing prayer)
revivespring-react/src/styles.css
```

## One thing to watch
Nano is a smaller model — for the "must always respond as a prayer" rule
specifically, it's worth spot-checking real conversations after this goes
live. Smaller models can occasionally drift from a strict format
instruction over a long chat history; if you notice that happening, the
next lever (before jumping back to a bigger model) is trimming how much
prior conversation history gets sent per request.
