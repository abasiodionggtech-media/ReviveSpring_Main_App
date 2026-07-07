# ReviveSpring — Professional Polish Audit

I went through the backend, Flutter app, and React web app looking for
things that would matter for a "professional, production-grade" bar —
not new features, just quality, safety, and polish. Organized by priority.
File paths included so these are actionable.

---

## 🔴 Critical — fix before wider release

1. **Hardcoded admin-promotion password in source code.**
   `backend/src/routes/admin.js` — `ADMIN_ROLE_CONFIRMATION_CODE = 'Greatsuccess$'`
   is a plaintext string committed to the repo. Anyone with repo access
   (now or in the future, including if the repo is ever made public,
   forked, or leaked) can read this and grant themselves admin. This
   should move to an environment variable (`ADMIN_ROLE_CONFIRMATION_CODE`
   in `.env`), never in code.

2. **CORS is wide open (`origin: '*'`) despite already having the
   infrastructure to restrict it.**
   `backend/src/index.js` hardcodes `origin: '*'` for every request,
   including ones that carry `Authorization` headers. Your own
   `.env.example` already documents an `ALLOWED_ORIGINS` variable for
   this — it's just never actually read in code. This should be wired up
   so only your own app/web domains can call the API with credentials.

3. **No crash reporting on mobile.** There's no Crashlytics/Sentry, and no
   `runZonedGuarded`/`FlutterError.onError` override in `lib/main.dart`.
   Right now, if something throws in production, you have zero visibility
   — no stack trace, no user count affected, nothing. This is one of the
   highest-value additions for a "professional" app: you want to know
   about crashes before users complain.

4. **API base URL is hardcoded in the mobile app.**
   `lib/services/api_service.dart` bakes
   `https://revivespring.onrender.com/api` directly into the default
   constructor value. There's no way to point a debug/staging build at a
   different backend without editing source. The React web app already
   does this correctly via `VITE_API_URL` — mobile should get the
   equivalent (`--dart-define=API_BASE_URL=...` read at build time).

## 🟠 High priority

5. **Zero real test coverage.** The only test file anywhere in the repo is
   `test/widget_test.dart` — one smoke test that checks the splash screen
   text. There is no backend test suite at all (no Jest/Mocha/Supertest;
   `package.json` has no test script or test dependency). For a
   "professional" bar, at minimum the auth flow, payment/webhook logic,
   and streak/subscription math deserve real tests — those are the places
   a silent bug costs you money or trust.

6. **Structured logging is missing.** The backend logs everything with
   `console.log`/`console.error` (see `src/index.js`, every route file).
   That's fine for a demo, but in production you can't filter by
   severity, redact sensitive fields, or ship logs anywhere searchable.
   Worth moving to a real logger (pino or winston) with log levels and a
   policy of never logging tokens/passwords/emails in full.

7. **Cron jobs run via `setInterval` inside the same process as the API
   server.** `src/index.js` runs the daily prayer email job every minute
   and the streak-grace job every hour using in-process timers. This
   works fine on a single instance, but if you ever scale to more than one
   server instance (which "professional" usually implies eventually),
   every instance will run these jobs simultaneously — meaning duplicate
   emails and duplicate notifications. Worth flagging now even though it's
   not urgent at your current scale.

8. **OTP codes are stored in plaintext in the database.**
   `backend/src/routes/auth.js` stores `otpCode` as-is on the `User` row.
   It's short-lived (10 minutes) so the risk is limited, but hashing it
   the same way passwords are hashed costs little and removes one more
   thing a database leak would expose.

9. **No API versioning.** All routes are `/api/...` with no version
   prefix (`/api/v1/...`). Not urgent today, but retrofitting versioning
   after you have real production traffic and an app store release is
   much more painful than starting with it.

## 🟡 Medium priority — polish and maintainability

10. **Branding inconsistency: "ReviveMe" vs "ReviveSpring."** Both names
    still appear across the codebase (`lib/data/app_data.dart`, the
    backend seed file, the React app) — leftover from what looks like an
    earlier project name. Worth a global find-and-replace pass so
    marketing copy, emails, and in-app text are consistent everywhere.

11. **`revivespring-react/src/App.tsx` is a single ~2,100-line file**
    containing every screen, modal, and helper function as dense
    single-line JSX. It works, but it's hard to review, hard to onboard a
    second developer into, and every edit risks touching unrelated code.
    Worth splitting into a proper `components/` and `screens/` folder
    structure with one file per screen — this is purely a maintainability
    concern, not a functional bug.

12. **Dead code left over from the onboarding rewrite.**
    `OnboardingChartCard`, `ChartBar`, `CHART_NAMES`, `CHART_SERIES` in
    `App.tsx` are no longer referenced by the current onboarding flow.
    Harmless, but worth deleting in a cleanup pass.

13. **A stray, incomplete file**: `backend/src/routes/aiChat22.js` (3
    lines, unused, not mounted anywhere). Looks like an accidental
    leftover — safe to delete.

14. **`.env.example` is slightly stale.** It still lists
    `OPENAI_MODEL=gpt-5.4` even though the code now defaults to
    `gpt-5.4-nano` when the variable is unset — worth keeping these in
    sync so a new developer setting up the project isn't confused.

15. **`pubspec.yaml` still has the default Flutter boilerplate
    description** (`"A new Flutter project."`). Small, but it's the kind
    of thing that makes a codebase feel unfinished to anyone who opens it.

## 🟢 Nice-to-have

16. **No OpenAPI/Swagger documentation** for the backend API. Not
    required, but if you ever bring on another developer (mobile, web, or
    backend), a generated API reference saves a lot of "what does this
    endpoint return" back-and-forth.

17. **No CI pipeline** (no `.github/workflows`, no automated `flutter
    analyze` / `npm run build` / backend syntax check on push). Even a
    minimal one that runs lint + build on every push would catch a broken
    commit before it reaches production.

18. **Accessibility pass hasn't been done** — things like semantic labels
    on icon-only buttons, color contrast on the darker screens (onboarding,
    sleep prayer), and screen-reader testing haven't been verified. Worth
    a dedicated pass once the feature set settles down.

19. **No app store assets audit** — I haven't verified app icons across
    all required sizes, splash screen configuration for both platforms, or
    that Play Store / App Store listing metadata (screenshots,
    descriptions, privacy policy link) is ready. Worth a checklist pass
    closer to launch.

---

## Suggested order of attack

If you want to tackle this in passes rather than all at once, I'd go:
1. Items 1–4 (security/reliability) — these are the ones that could
   actually hurt you.
2. Item 5 (tests) for at minimum auth + subscription/payment logic.
3. Items 6–9 as the app gets closer to real scale.
4. Items 10–15 whenever you have a slower week — pure cleanup, zero risk.
5. Items 16–19 as launch approaches.

Let me know which of these you want me to actually fix, and I'll work
through them in whatever order you prefer.
