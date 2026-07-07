# Onboarding Redesign — What Changed

Replaced the old onboarding flow entirely with the new 25-question flow you
provided (7 sections), on both Flutter mobile and the React web app. Same
app colors and visual language as before — dark shell, emerald/lime accents,
glassy cards — just a full content and interaction rebuild.

## Two intentional scope decisions

1. **Screen 1 (Language) was not duplicated.** Your app already has a
   dedicated language-selection screen before signup (`LanguageScreen` /
   `/language` route). Adding a second language prompt inside onboarding
   would ask the same question twice, so the new flow starts at Screen 2
   (the welcome tour) and picks up from there.
2. **"Shake" gesture and photo upload were not added.** The spec mentioned
   "shake/tap" for one screen (not present in this batch, that was Day 2)
   and an optional profile photo here. Photo upload has no backend endpoint
   in this codebase yet, so the photo button is present in the UI but shows
   "coming soon" rather than silently failing. Happy to wire up real photo
   upload if you want it — it needs a small backend addition (image upload
   endpoint + storage).

## How it works now
- Every question in your 7 sections is implemented: Faith Background,
  Prayer Needs, Spiritual Goals, Daily Rhythm, Faith Personalization, and
  Final Steps — including multi-select caps ("choose up to 3", "up to 2"),
  the "select all that apply" with an exclusive "None of these" option,
  the optional/skippable denomination screen, the time-zone-aware reminder
  wheel picker, and the final summary card.
- **Premium screen** reuses your existing `PremiumUpgradeSheet` (mobile)
  purchase flow — no new payment code, no risk of a broken buy button. The
  web version currently has no payment integration built at all, so its
  "Upgrade to Premium" button shows an honest note pointing to Settings
  rather than faking a purchase.
- **Email confirmation** doesn't attempt to change your login email (no
  backend endpoint exists for that) — it stores a preferred contact email
  for the daily devotional and tells the user where to actually change
  their login email later.
- All answers save through your existing `/onboarding/save` endpoint
  (unchanged on the backend) plus the name update goes through your
  existing `PATCH /auth/me`. No backend changes were needed for this one.

## Files touched
```
lib/data/app_data.dart              (new OnboardingStep/OnboardingOption model + full 25-step list)
lib/core/app_controller.dart        (onboardingSteps rename, updateFullName helper)
lib/screens/onboarding_screen.dart  (fully rewritten)
revivespring-react/src/App.tsx      (new step types/list, OnboardingPage rewritten)
revivespring-react/src/styles.css   (new CSS for tour/email/profile/premium/summary cards)
```
