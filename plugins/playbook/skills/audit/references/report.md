# Building the Report

Fill `${CLAUDE_SKILL_DIR}/assets/report-template.html` and publish it.

---

## Steps

1. **Read the template.** It uses `{{PLACEHOLDER}}` markers and repeatable
   blocks marked with HTML comments.

   The template is deliberately a **fragment** — it has no `<!doctype>`,
   `<html>`, `<head>` or `<body>` tags. Publishing it as an artifact wraps it in
   that skeleton automatically, and a browser opening it as a local file
   supplies the same tags itself. **Do not add them**, or the artifact publish
   breaks.
2. **Write the filled file outside the project** — a temp directory or the
   user's home directory. Never inside the audited repo. Name it
   `<project>-readiness-<YYYY-MM-DD>.html`.
3. **Publish it** with the `Artifact` tool so the user gets a shareable link.
   Pass `icon: "chart"` and a one-line `description`.
4. **If `Artifact` is unavailable**, leave the file on disk and give the user
   the complete absolute path, telling them to open it in a browser.

---

## Placeholders

| Placeholder | Value |
|---|---|
| `{{PROJECT_NAME}}` | The repo/folder name, title-cased if it reads better |
| `{{STACK_SUMMARY}}` | "Next.js · Postgres · Vercel · Stripe" — the plain-English fingerprint |
| `{{DATE}}` | Today, as `20 October 2026` |
| `{{PROJECT_PATH}}` | Absolute path audited |
| `{{PCT}}` | The percentage, integer, no `%` sign |
| `{{RING_FILLED}}` | **Compute:** `round(364.4 × PCT / 100)` |
| `{{RING_COLOR}}` | `var(--ok)` ≥80 · `var(--warn)` 60–79 · `var(--bad)` <60 |
| `{{VERDICT_HEADLINE}}` | "Production ready" / "Close — fix critical gaps first" / "Not production ready" / "Demo-grade only". **If a gate failed, this says "Not production ready" regardless of the band** |
| `{{VERDICT_DETAIL}}` | One or two sentences. Lead with the single most important thing |
| `{{EARNED}}` `{{APPLICABLE}}` `{{N_SCORED}}` `{{N_NA}}` | The scoring arithmetic |
| `{{TIER_NOTE}}` | e.g. ` · Scored as a live app taking payments` — or delete |
| `{{GATE_DETAIL}}` | Which gate failed and why, in one sentence |
| `{{SCOPE_NOTE}}` | Any limit on what you read — or delete the line |

### The ring

`stroke-dasharray="{{RING_FILLED}} 364.4"` — the circle's circumference is
364.4 (r=58). So 68% → `248`. Get this right; a wrong arc undermines the whole
report at a glance.

---

## Repeatable blocks

Each is marked `<!-- repeat ... -->` in the template. Duplicate the element once
per item and delete the comment.

**Strengths** — 3 to 5, each with real evidence. This section exists because a
report opening with twenty failures gets closed. Never fabricate one; if there
are genuinely only two, use two.

**Layer grid** — one `.lyr` per layer, all 23, in order. Class:

| Class | Score |
|---|---|
| `ok` | 7–10 |
| `wn` | 4–6 |
| `bd` | 1–3 |
| `na` | N/A — set `{{LAYER_SCORE}}` to `N/A` |

For an N/A layer, use `{{LAYER_NA_REASON}}` to give the reason inline, as
` — serverless` or ` — no AI features`. Leave it empty on scored layers.

Keep `<span class="g-tag">gate</span>` only on gate layers (4, 8, 12, 13, and
18/20 when they apply). Delete it everywhere else.

**Findings** — one per real problem, ordered worst first. Use `crit` for gate
failures and 🔴 layers, `high` for 🟡.

- `{{SEVERITY}}` — "Critical" (pill `red`), "High" (pill `red`), "Medium"
  (pill `amber`), "Low" (pill default)
- `{{EFFORT}}` — "Low · under an hour", "Medium · a day", "High · multi-day"
- Delete the `<pre><code>` block when a snippet would not genuinely help.
  A snippet of the *fix* helps; a snippet of the broken code rarely does
- `{{FINDING_EVIDENCE}}` — `src/routes/auth.ts:42`

**Quick wins** — 2 or 3. Under an hour each, real impact, specific file. For a
non-developer this is the most valuable part of the report. `{{WIN_TIME}}` is a
short time estimate shown as the marker, e.g. `20m` or `45m`.

**Priority order** — the numbered list from `scoring.md`, reduced to the items
that actually apply to this project. Do not list a priority with no finding
behind it.

---

## Writing style for the report

The reader may not write code.

- **What** — the problem in one sentence, no jargon: *"Anyone can try passwords
  on your login page as many times as they like."*
- **Why it matters** — the real consequence: *"An attacker can run through
  common passwords automatically until one works."*
- **Fix** — the specific first step and the file it belongs in
- **Effort** — honest, not optimistic

Never write "simply" or "just". Name a technology only when they need it to act.

## Never put in the report

- **A secret value.** Write *"a credential appears at `src/config.js:14`"* and
  nothing more. Not the value, not a masked version, not the first four
  characters. The report is made to be shared
- Full file contents, or long code dumps from their project
- Personal data found in seed files, fixtures or test records
- Internal hostnames, connection strings, or private URLs
- A finding you did not verify by reading the file

## Final chat message

Three lines, then the link. Do not paste the report into chat.

```
Score: 68% (14 of 23 layers applicable)
Verdict: Not production ready — authentication has a critical gap
Start here: add rate limiting to the login endpoint (about an hour)
```

Then offer, in one line, to walk through any finding or fix the top item
together. Do not start fixing anything unless they ask.
