# The 23 Layers

Score each applicable layer **1–10, or N/A**. Every score needs a `file:line`.

🚪 = **gate layer**. A 🔴 (1–3) here means NOT production ready regardless of
the overall percentage. See `scoring.md`.

---

## Layer 1 — Frontend

- Loading state on every async action?
- **Empty states** — "no items yet" plus how to create one. An empty screen looks broken
- **Error states** on every failed request — never fails silently
- Error boundaries — one crashed component must not blank the whole app
- Mobile tested on a real viewport, not just a resized desktop window
- Bundle size reasonable; assets lazy-loaded
- No `console.log` left in production code, no hardcoded URLs

**The unhappy path — check this first. It is the most common gap in AI-built apps.**
An AI builds the happy path and almost never the unhappy one.

- Does every async action have all five states: idle, loading, success, **empty**, **error**?
- Do error messages say **what happened, whose fault it is, and what to do next**? "Something went wrong" says nothing and offers nothing
- Raw stack traces, SQL, internal IDs or file paths ever shown to a user? (Also Layer 8)
- Explicitly handled: network drop mid-request, timeout, expired session (401), empty result, partial failure, permission denied (403), third-party outage?
- Empty `catch {}` blocks that swallow errors — grep for them
- Loading spinners with no timeout? An infinite spinner is worse than an error

**Forms:** correct input types (numeric keypad for phone, date picker not text
field), validation as the user types, specific error messages, descriptive
submit button, 44px minimum touch targets.

## Layer 2 — APIs and Backend

- Every route has a server-side auth check — not just a hidden UI element
- Frontend never talks to the database directly
- Input validated at the boundary (schema validation, not hand-rolled `if`s)
- No stack traces leaking to clients; consistent error shape
- **No endpoint returns 200 on failure** — grep `catch` blocks that return success
- API versioned (`/api/v1/`) if anything external consumes it
- Business logic (pricing, permissions, feature gating) server-side only — never in the frontend
- Responses return only needed fields — no `SELECT *` piped to JSON, no PII by default
- Sequential integer IDs exposed? Enables enumeration — prefer UUIDs
- Heavy work (PDF generation, email, multiple external calls) done asynchronously, not inline in the request
- Retries with backoff + idempotency keys on writes

## Layer 3 — Database and Storage

- Schema defined in version control; **migrations as numbered files**, never hand-run `ALTER TABLE` on production
- Queries parameterised — no string concatenation with user input
- Indexes on frequently queried and sorted columns
- No unbounded queries — every list endpoint paginated
- No N+1 patterns — queries inside loops are the classic offender
- Files/media in object storage, not database columns
- **Separate database per environment** (see Layer 5)
- Constraints at the DB layer: `NOT NULL`, `UNIQUE`, `CHECK`, foreign keys — not only in app code
- Money stored as integers in minor units, never floats
- Data residency: can you answer "where is this data physically stored?" If it matters contractually, is it guaranteed or merely a best-effort hint?

## Layer 4 — Auth and Permissions 🚪

> **Hard cap — scores at most 3:** any endpoint returns another user's data, or
> passwords are stored unhashed. Apply before any judgement (`scoring.md`).

- Passwords hashed with bcrypt / argon2 / PBKDF2 + per-user salt. **Plain SHA or MD5 is a critical finding**
- Sessions expire, and expiry is enforced server-side
- Tokens invalidated on logout and on password change
- CSRF protection on mutating endpoints
- **Test it: can user A reach user B's data by changing an ID in the request?**
- Admin routes verify an explicit admin flag on the server
- Permission-based, not just role-based: `hasPermission(user,'can_delete')` beats `user.role === 'admin'`
- JWTs: algorithm pinned server-side (not read from the token), expiry set
- Password reset tokens single-use and time-boxed

**Multi-tenant (if applicable — highest consequence in the audit):**
- Every tenant-scoped query filters on the tenant key
- Service/admin keys bypass row-level security — so the tenant filter must exist in application code too
- Cache keys tenant-scoped
- Exports (CSV/PDF) tenant-scoped
- Background jobs carry tenant context

## Layer 5 — Hosting and Deployment

- Staging environment that is genuinely separate from production
- Rollback path that exists and has been tested
- No direct pushes to the main branch
- Environment variables set per environment
- Zero-downtime deploys; schema migrations and auth changes not shipped to 100% of users at once

**Environment separation — the second most common gap in AI-built apps.**
An AI sees one database binding and uses it. Nothing in the code looks wrong.

- **Is dev/staging pointing at the production database?** Compare the actual connection strings or database IDs, not the names
- **Run this against production:**
  `SELECT * FROM users WHERE email LIKE '%test%' OR email LIKE '%example.com';`
  Rows returned means there is no real separation — just one environment with two names
- Separate per environment: database, object storage, queues/caches, third-party API keys, analytics and error-tracking projects
- Email safety net in dev — can a test send reach a real inbox?
- Payments in test mode in dev — can a dev checkout create a live charge?
- **Scheduled jobs / cron** disabled or pointed at dev resources? A dev cron against production data is a silent disaster
- An `is_test` column instead of a separate database is a filter someone will forget, not separation

## Layer 6 — Cloud and Compute

- Secrets in environment variables or a secret store — never committed
- Billing alerts configured. Know before the invoice does
- Platform limits understood (request duration, memory, payload size, free-tier caps)
- No heavy synchronous work inside a serverless function

## Layer 7 — CI/CD

- Automated tests run in the pipeline
- Deploys gated on tests passing
- Lint and type checking in CI
- `.env.example` lists every required variable
- Branch protection on main; PR required
- Secret scanning on every PR (TruffleHog, GitGuardian, or the host's own)

## Layer 8 — Security 🚪

> **Hard cap — scores at most 3:** a live secret in the repository or its git
> history. Apply before any judgement (`scoring.md`).

- **Secrets in the codebase?** Grep for `API_KEY =`, `password =`, `secret =`, `token =`, `sk_live`, `-----BEGIN`
- **Git history clean?** A key ever committed is compromised and must be rotated, even if later removed
- HTTPS enforced; dependencies reasonably current (`npm audit` / equivalent)
- CORS locked to known origins, not `*`
- Security headers: `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, `Referrer-Policy`
- Input sanitised against XSS and injection
- **Logs never contain** passwords, tokens, session IDs or PII
- Bot protection (CAPTCHA/Turnstile) on auth and public form endpoints
- Every third-party package verifiable in its registry — AI-suggested packages that don't exist are a real supply-chain vector

**AI-generated code carries elevated risk.** Assume XSS and log-injection until
proven otherwise, and check the full git history for secrets.

## Layer 9 — Rate Limiting

- Auth endpoints (login, signup, password reset) throttled, with attempts persisted
- Expensive operations protected: file uploads, email sends, AI calls, document generation
- Rate-limited responses return 429, not 500
- Any endpoint triggering several expensive services in one request treated as high-risk
- No unauthenticated expensive operations

## Layer 10 — Caching

- Static assets cached with long TTLs
- Expensive repeated queries cached
- **Invalidation on write** for user-specific data — permissions, account status, pricing must never rely on TTL alone
- No private or authenticated data cached at a shared edge
- Cache keys tenant-scoped in multi-tenant apps

## Layer 11 — Load Balancing and Scaling

*Often N/A or 8/10 on serverless and managed platforms — say which.*

- App stateless; sessions in a shared store, not in memory
- Load tested to a realistic multiple of expected peak
- Tables tested with realistic row counts, not ten rows of fixture data
- High-write counters pre-aggregated rather than counted on every page load

## Layer 12 — Error Tracking and Logs 🚪

> **Hard cap — scores at most 3:** no uptime check or alert outside the app
> itself. Apply before any judgement (`scoring.md`).

- Error tracking integrated (Sentry or equivalent), **frontend and backend**
- Alerting on error-rate spikes
- Structured logs — JSON objects with fields, not sentences
- Correlation ID following a request across services
- **Business-metric monitoring**, not just server health. Signups per hour, payments per hour. A 40% revenue drop with green dashboards is a silent failure
- Uptime monitoring with a `/health` endpoint
- **The discovery question:** "if this went down right now, how would you find out?" If the answer is "a customer would email me", this layer is 🔴 regardless of what is installed

## Layer 13 — Availability and Recovery 🚪

> **Hard cap — scores at most 3:** no backup stored apart from the primary
> database, or no restore ever practised. Apply before any judgement
> (`scoring.md`).

- Automated backups — and **has a restore actually been tested?** A backup never restored is a hypothesis
- Backup stored separately from the primary database. Same-server backup is a second copy of the same risk
- RPO defined: how much data loss is acceptable? Does backup frequency match it?
- RTO defined: how long can it be down?
- A one-page incident runbook, written while calm
- Status page or a plan for telling users during an outage

## Layer 14 — AI Pipeline

*N/A in most projects.*

- AI endpoints authenticated **before** the model is called — a public AI endpoint is a billing emergency
- Per-user spend caps enforced server-side
- Payload size and schema validated at the gateway
- Retries with backoff; fallback when the model is unavailable
- Model version pinned
- Token consumption logged per user

## Layer 15 — Documentation

- A README with honest setup instructions that someone else has actually followed
- `.env.example` documenting every variable
- Architecture decisions recorded with their reasoning — why, not just what
- An `AGENTS.md` / `CLAUDE.md` or equivalent, if AI assistants work in this repo
- Known issues and workarounds written down
- A runbook for the most likely failure modes

## Layer 16 — Legal and Compliance

*N/A for internal tools with no personal data and no payments.*

- Privacy policy published and linked, accurately reflecting what is collected
- Terms of service published and linked
- Cookie/tracking notice if analytics are in use
- **Account deletion that actually purges records** — not just an inactive flag
- Deletion propagated to third parties: analytics, error tracking, email provider
- Refund policy published if taking payments
- DPA ready for business customers; subprocessor list maintained
- Data retention period defined
- Cross-border transfer basis documented if users are in a regulated jurisdiction

## Layer 17 — Testing and Quality Gates

- **The AI testing problem:** an agent that wrote both the code and the tests
  writes tests that pass. It tests what the code *does*, not what it *should*
  do. Were these tests written from the spec, or from the implementation?
- Critical path covered: login → core action → payment
- Coverage gate that **fails the build**, not a number printed in logs
- Tests independent — each creates and tears down its own data
- Tests use a separate database and mock external services. **No network calls in tests**
- Failure paths tested, not just happy paths
- Flaky tests quarantined and tracked, not masked with permanent retries
- **Prove it:** would inverting one critical conditional make the suite fail? If not, coverage is decorative

## Layer 18 — Time, Timezones and Scheduling 🚪*

*\*Gate layer when the app reasons about dates, shifts or schedules. N/A if it never does.*

- All timestamps stored in UTC or epoch seconds
- Timezone stored as a **zone name** (`Europe/London`), not an offset (`+01:00`). Offsets don't survive daylight saving
- Date-only values (a shift date, a holiday) stored as dates, not instants. An instant shifts a day across a timezone boundary
- "Today" computed in the **user's or tenant's** zone, not the server's
- Daylight saving transitions handled — the 23-hour and 25-hour days
- **Scheduled jobs: what timezone does the cron run in?** Most platforms run cron in UTC, so a "9am daily" job drifts by an hour twice a year
- Date arithmetic via a library, never manual `+ 86400000` (wrong on DST days)
- Device clock not trusted for anything auditable — the server assigns timestamps
- Tests include a non-UTC timezone and a DST boundary date

## Layer 19 — Offline and Sync Resilience

*N/A for desk-only tools on reliable connectivity — say so explicitly.*

**The test that matters:** turn on airplane mode *mid-task* and submit. If the
user loses their input, this layer scores 1.

- Writes queued locally when offline and replayed on reconnect
- Each queued write carries an idempotency key **generated at enqueue time**, not send time — otherwise a retry creates a duplicate
- Queue persisted (IndexedDB / local storage / SQLite), surviving an app kill
- Pending state visible in the UI. A silent optimistic tick that never syncs is a lie
- Conflict strategy chosen and documented. "Undecided" means last-write-wins by accident
- Reconnect storms bounded and jittered
- Partial failure surfaced — 8 of 10 writes succeeded, which 2 didn't?

## Layer 20 — Audit Trail and Data Integrity 🚪*

*\*Gate layer when the app is a record of truth — attendance, compliance, safety, financial.*

**An audit trail is not application logs.** Logs are for debugging and get
deleted. An audit trail is queryable evidence, retained per obligation, and it
is what you hand a customer in a dispute.

**Your AI built the actions — it never built the receipts.** Check these
specific actions are logged, by name:

- Plan upgrade / downgrade / cancellation (billing disputes)
- **Email address change — old and new address both recorded?** The classic account-takeover step
- Password / MFA change
- Permission or role change — "who made them an admin?"
- Record deletion — the most common support ticket there is
- Data export or bulk download
- **Admin acting on behalf of a user** — the most under-logged action in any business app
- Payment method change; tenant membership change

**Mechanics:**
- Each entry records **actor, action, target, timestamp, source** (IP / device)
- **Append-only** — no `UPDATE`/`DELETE` on audit rows, enforced by permissions, not convention
- Edits to records of truth preserve the prior value — not a silent overwrite
- Actor recorded for automated and admin actions too ("system", "cron", "admin as user")
- Tenant-scoped and exportable without leaking other tenants

**Data integrity:**
- Foreign key enforcement **verified, not assumed** — try a deliberate orphan insert
- Enum-ish columns constrained so a typo can't invent a fourth status
- Business uniqueness enforced by a unique index, not a `SELECT`-then-`INSERT` race

## Layer 21 — Accessibility

*N/A for CLIs, libraries and backend services.*

Target **WCAG 2.2 AA**. Legal exposure: ADA (US), European Accessibility Act
(EU), Equality Act (UK). Staff-facing software counts.

- Every interactive element operable by keyboard alone
- Visible focus indicator — no `outline: none` without a replacement
- Focus managed on route change, trapped in modals, returned on close
- Real `<label>` elements. **A placeholder is not a label** — it disappears on typing
- Form errors linked via `aria-describedby` and announced, not just a red border
- Contrast ≥ 4.5:1 body text, 3:1 large text and UI boundaries
- Information never conveyed by colour alone
- Semantic HTML — `<button>`, not `<div onclick>`. One `<h1>`, no skipped heading levels
- Meaningful `alt` text; `alt=""` on decorative images
- `prefers-reduced-motion` respected
- **Custom dropdowns, modals and date pickers built from `<div>`s** — the most common serious offender in AI-generated frontends
- Run `npx @axe-core/cli <url>` or Lighthouse — a floor, not proof. Automation catches roughly a third of failures

## Layer 22 — Launch Presentation and Share Assets

*N/A for CLIs, libraries and backend services.*

**The test:** paste the production URL into a messaging app. A bare grey link
means this layer is failing at the exact moment the product gets shared.

- Favicon replaced — **not the framework default**. A Vite or React logo in production is an instant credibility loss
- `apple-touch-icon.png` at 180×180 and **opaque**. Transparency renders as a **black square** on iOS home screens
- Web app manifest with 192/512 icons plus a **maskable** variant (logo inside the centre 80%, or Android crops it)
- **iOS ignores manifest icons for the home screen** — it uses `apple-touch-icon`, or a screenshot of the page if absent
- Open Graph tags: `og:title`, `og:description`, `og:image`, `og:url`, plus `twitter:card`
- **`og:image` is an absolute URL** — relative paths silently fail, the top cause of blank previews
- **`og:image` publicly reachable with no auth** — crawlers have no session cookie. Test in a private window
- 1200×630, text legible at thumbnail size, not pointing at a staging domain
- Unique `<title>` and meta description per page
- `<html lang>` set; canonical URL, `robots.txt`, `sitemap.xml`
- Custom 404 page styled like the app
- Transactional email has a real sender **name**, branded template, working reply-to
- Any generated document (PDF, invoice, export) branded — if the product's output is a document, that document *is* the product

## Layer 23 — Marketing Foundations

*Score lightly, or N/A, for internal tools.*

- A one-liner exists and is used consistently: "[Product] helps [who] [do what] without [pain]"
- Landing page above the fold answers: what it is, who it's for, proof, one call to action
- The same one-liner reused in the meta description and `og:description` — not three different descriptions
- Real screenshot of the product, not an illustration
- Custom domain, not a bare `*.vercel.app` / `*.workers.dev` URL
- Funnel defined in analytics: landed → signed up → first core action → returned
- Trust signals: real contact details, human-written legal pages, a changelog

---

## Stack-specific notes

**Cloudflare Workers / D1 / Pages**
- Layer 11: platform-handled → N/A or 8/10
- Layer 12: error tracking is almost always missing — Sentry's Workers SDK is the fix
- Layer 13: D1 has no native point-in-time recovery — scheduled exports to object storage, in a different region
- Layer 3: a query inside a loop is one HTTP round trip per iteration. Replace with `IN(...)` and batch
- Layer 18: Cron Triggers run in **UTC**
- Layer 5: compare `database_id` between environments, not database names

**Next.js / Vercel**
- Check auth on every route handler individually, not only in middleware
- `NEXT_PUBLIC_` prefixed variables are shipped to the browser — grep for secrets with that prefix
- Open the production build and search it for API routes and credentials

**Node / containers**
- Connection pooling configured?
- Structured logs shipped to a sink, not raw stdout
- Base image patched; not running as root

**Django / Rails / Laravel**
- `DEBUG = False` in production — a debug page leaks everything
- `SECRET_KEY` / `APP_KEY` from the environment, not committed
- The framework's own security checklist run (`manage.py check --deploy`)

**AI-generated codebases (Lovable, Bolt, v0, Cursor-heavy)**
- Assume XSS and log-injection risk until proven otherwise
- Verify every third-party package actually exists in its registry
- Scan the **full git history** for secrets, not just the working tree
- Expect Layer 1 (unhappy path), Layer 5 (environment separation) and Layer 20 (audit trail) to be the three weakest
