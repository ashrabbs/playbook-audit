# Discovery — Fingerprinting an Unknown Stack

Work out what this project is, then work out **which layers don't apply to it**.
Getting the N/A set right is what makes the score honest on a stack you have
never seen before.

---

## 1. Language and framework

Look for these in the project root. Several may be present.

| Marker file | Stack | Plain-English label |
|---|---|---|
| `package.json` | Node / JavaScript / TypeScript | read `dependencies` to narrow it |
| ↳ contains `next` | Next.js | "a Next.js web app" |
| ↳ contains `react` (no next) | React | "a React web app" |
| ↳ contains `vue` / `nuxt` | Vue / Nuxt | "a Vue web app" |
| ↳ contains `svelte` | Svelte | "a Svelte web app" |
| ↳ contains `express` / `fastify` / `hono` | Node API | "a Node.js backend" |
| ↳ contains `react-native` / `expo` | React Native | "a mobile app" |
| ↳ contains `electron` | Electron | "a desktop app" |
| `requirements.txt`, `pyproject.toml`, `Pipfile` | Python | — |
| ↳ contains `django` | Django | "a Django web app" |
| ↳ contains `flask` / `fastapi` | Flask / FastAPI | "a Python API" |
| `go.mod` | Go | "a Go service" |
| `Cargo.toml` | Rust | "a Rust project" |
| `composer.json` | PHP | "a PHP app" (check for `laravel`) |
| `Gemfile` | Ruby | "a Ruby app" (check for `rails`) |
| `pubspec.yaml` | Flutter / Dart | "a Flutter mobile app" |
| `build.gradle`, `pom.xml` | Java / Kotlin | "a Java service" |
| `Package.swift`, `*.xcodeproj` | Swift | "an iOS app" |
| `mix.exs` | Elixir | "an Elixir app" |
| `*.csproj`, `*.sln` | .NET | "a .NET app" |
| only `.html` / `.css` / `.js`, no manifest | Static site | "a plain website" |

**Say the plain-English label to the user, never the filename.** "A Next.js web
app" means something to them; `package.json` does not.

## 2. Hosting and deployment

| Marker | Target |
|---|---|
| `wrangler.toml` / `wrangler.jsonc` | Cloudflare Workers / Pages |
| `vercel.json` / `.vercel/` | Vercel |
| `netlify.toml` | Netlify |
| `fly.toml` | Fly.io |
| `Procfile` | Heroku / Railway-style |
| `Dockerfile`, `docker-compose.yml` | Containers |
| `serverless.yml` | AWS Lambda / Serverless Framework |
| `app.yaml` | Google App Engine |
| `.github/workflows/*.yml` | GitHub Actions CI |
| `.gitlab-ci.yml` | GitLab CI |
| `amplify.yml` | AWS Amplify |
| none of the above | Possibly undeployed, or deployed by hand — **that is itself a Layer 5 finding** |

## 3. Data, auth and services

Grep rather than assume paths.

| Looking for | Search for |
|---|---|
| Database | `prisma/`, `*.sql`, `migrations/`, `drizzle`, `sequelize`, `mongoose`, `supabase`, `d1_databases`, `DATABASE_URL` |
| Auth | `next-auth`, `passport`, `clerk`, `auth0`, `firebase-auth`, `supabase.auth`, `bcrypt`, `argon2`, `pbkdf2`, `jsonwebtoken`, `session` |
| Payments | `stripe`, `paddle`, `lemonsqueezy`, `braintree`, `paypal` |
| Email | `resend`, `sendgrid`, `postmark`, `nodemailer`, `ses`, `mailgun` |
| Error tracking | `sentry`, `bugsnag`, `rollbar`, `datadog` |
| Analytics | `posthog`, `plausible`, `mixpanel`, `segment`, `gtag` |
| Tests | `*.test.*`, `*.spec.*`, `__tests__/`, `tests/`, `pytest`, `vitest`, `jest` |
| Background jobs | `queue`, `worker`, `celery`, `sidekiq`, `bullmq`, `cron` |
| AI features | `openai`, `anthropic`, `@ai-sdk`, `langchain`, `replicate` |

## 4. Is it multi-tenant?

Decides a large share of Layer 4 and Layer 20. Grep the schema and queries for
`org_id`, `organization_id`, `tenant_id`, `account_id`, `workspace_id`,
`team_id`, `company_id`, or a domain-specific equivalent.

If present, **tenant isolation becomes the highest-consequence check in the
audit**. If absent and the app is single-user or internal, say so and move on.

## 5. Derive the N/A set

This is the step that makes the percentage fair. Mark a layer N/A **and say
why** — never score an absent layer 1/10.

| Layer | N/A when |
|---|---|
| 3 Database | No database at all (static site, pure frontend) |
| 4 Auth | No user accounts — nothing to log into |
| 9 Rate Limiting | No public write endpoints (static site) |
| 10 Caching | Static site served entirely by a CDN |
| 11 Load Balancing | Serverless/managed platform handles it — N/A or 8/10 |
| 14 AI Pipeline | No AI features (this is N/A in most projects) |
| 16 Legal | No personal data, no payments, internal tool only |
| 18 Time & Scheduling | Nothing in the app reasons about dates, shifts or schedules |
| 19 Offline & Sync | Desk-only tool on reliable connectivity, no mobile client |
| 20 Audit Trail | No sensitive actions and not a record of truth |
| 21 Accessibility | No user interface at all — CLI, library, backend service |
| 22 Share Assets | No web interface — CLI, library, backend service |
| 23 Marketing | Internal tool with no public presence and no prospective users |

**Never N/A:** Layers 1 (if there is any UI), 2, 5, 6, 7, 8, 12, 13, 15, 17.
Every project has code, deployment, security, observability, documentation and
testing — even if the honest score is 1.

## 6. Tier the expectations

Score against what this project actually needs, not an enterprise ideal.

| Tier | Signals | Focus |
|---|---|---|
| **Side project / pre-launch** | No users yet, no payments, no CI | Layers 8, 12, 13. Don't punish missing load balancing |
| **Live, small** | Real users, no payments | Add 4, 9, 17, 20 |
| **Live, taking money** | Payments wired up | Full audit. 16 blocks launch |
| **Multi-tenant B2B** | Tenant column in schema | 4 and 20 become the headline |

State the tier in the report. A side project scoring 55% is in a different
situation from a payment-taking app scoring 55%, and the report should say so.

## 7. What to tell the user before scoring

One short paragraph, plain English, no lists of filenames:

> "This looks like a Next.js web app with a Postgres database, deployed on
> Vercel, with Stripe payments and GitHub Actions running tests. I'll skip the
> AI and offline sections since they don't apply here. Scoring 20 of the 23
> areas now — this takes a few minutes."

If the fingerprint is wrong, they will correct you now, before you waste the
whole audit on the wrong assumptions.
