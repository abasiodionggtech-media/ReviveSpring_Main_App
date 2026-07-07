# Two-Plan Subscription — What Was Built

Standard ($9.25/mo) and Premium ($15.50/mo) plans, both billed as a
3-month first payment with a 4% discount, on the mobile app — backend
fully supports both apps; web checkout UI is intentionally left for later,
as you said.

## Backend
- **New `standard` tier** everywhere a plan is checked: `effectivePlan()`,
  new `isPaidUser()` / `planAtLeast()` helpers in `services/monetization.js`
  for when you're ready to split features by tier.
- **Pricing now lives in settings** (`AppSetting` table, editable from the
  admin dashboard): `subscription_standard_price_usd` (9.25),
  `subscription_premium_price_usd` (15.50), `subscription_first_term_months`
  (3), `subscription_first_term_discount_percent` (4), and two Google Play
  product ID settings — no schema migration needed, these are just rows.
- **`GET /api/monetization/status`** now returns a `plans` array (one entry
  per tier) with monthly price, full 3-month price, the discounted
  first-term price, and the Google Play product ID — the single old
  `pricing` object is gone, replaced by this list.
- **`POST /api/monetization/subscription/mobile-sync`** now reads which
  product ID was purchased, sets the user's plan to `standard` or `premium`
  accordingly, and sets the expiry to a full 3 months instead of 30 days.
- **Admin dashboard** (`/admin/users/:id/plan`) now accepts `standard` as a
  valid plan value, and the dashboard UI has a proper 3-way dropdown
  (Free/Standard/Premium) instead of a single upgrade/downgrade toggle. A
  "Standard users" stat was added alongside the existing "Premium" one.

## Mobile (Flutter)
- **New plan-selection sheet** (`PremiumUpgradeSheet`, same `.show()` call
  site as before) — two side-by-side cards for Standard and Premium, each
  showing the monthly price, the discounted first-term total with the full
  price struck through, a "4% off" badge, and a short feature list per
  tier. Tapping a card selects it; one button then starts checkout for
  whichever is selected.
- `AppController.activateGooglePlayBilling` / `restoreGooglePlayBilling` now
  take a `tier` argument and look up the right product ID automatically.
- `AppUser` gained `isStandard` and `isPaidPlan` getters for future
  feature-gating (not wired into any gates yet, per your note that we'll
  split features by plan in a follow-up).

## Web
- No new checkout UI, as agreed. I did fix one thing so nothing looks
  broken: the profile page's premium panel referenced the old single
  `pricing` object, which no longer exists — it now reads the new `plans`
  list and shows both prices with a note that subscriptions are on Android
  for now.

## What to add in Google Play Console
1. Create two **subscription** products (not one-time products):
   - `revivespring_standard_3mo` — base price $9.25, billed every 3 months
   - `revivespring_premium_3mo` — base price $15.50, billed every 3 months
   (You can rename these, just update the two Google Play product ID
   settings in the admin dashboard to match exactly.)
2. On each, add an **introductory price** for the first billing period at
   4% off the 3-month total, so Google applies the discount natively.
3. Keep the old `revivespring_premium_monthly` product *inactive* rather
   than deleting it, so nobody currently subscribed on it gets disrupted —
   the backend still recognizes any unrecognized product ID as premium, so
   old subscribers keep working.

## Files touched
```
backend .../src/services/monetization.js   (standard tier, isPaidUser, planAtLeast)
backend .../src/routes/monetization.js     (plans array, tier-aware mobile-sync)
backend .../src/routes/admin.js            (standard in plan validator + stats)
lib/models/app_user.dart                   (isStandard, isPaidPlan)
lib/core/app_controller.dart               (tier-aware billing, plan getters)
lib/widgets/premium_upgrade_sheet.dart      (full rewrite — two-plan picker)
revivespring-react/src/App.tsx             (plans type, admin 3-way select, profile fix)
```
