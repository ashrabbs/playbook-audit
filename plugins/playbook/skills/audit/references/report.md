# Building the Report

Fill `${CLAUDE_SKILL_DIR}/assets/report-template.html` and publish it.

---

## Steps

1. **Read the template.** It uses `{{PLACEHOLDER}}` markers and repeatable
   blocks marked with HTML comments.

   The template is deliberately a **fragment** — no `<!doctype>`, `<html>`,
   `<head>` or `<body>` tags. Publishing it as an artifact wraps it in that
   skeleton automatically, and a browser opening it as a local file supplies the
   same tags itself. **Do not add them**, or the artifact publish breaks.

2. **Write the filled file outside the project** — a temp directory or the
   user's home directory, never inside the audited repo. Name it
   `<project>-readiness-<YYYY-MM-DD>.html`.

3. **Publish it** with the `Artifact` tool so the user gets a shareable link.
   Pass `icon: "chart"` and a one-line `description`.

4. **If `Artifact` is unavailable**, leave the file on disk and give the user the
   complete absolute path to open in a browser. The copy buttons still work.

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
| `{{VERDICT_HEADLINE}}` | "Production ready" / "Close — fix critical gaps first" / "Not production ready" / "Demo-grade only". **If a gate failed this says "Not production ready" regardless of the band** |
| `{{VERDICT_DETAIL}}` | One or two sentences, leading with the single most important thing |
| `{{EARNED}}` `{{APPLICABLE}}` `{{N_SCORED}}` `{{N_NA}}` | The scoring arithmetic |
| `{{N_BAD}}` `{{N_WARN}}` `{{N_OK}}` | **Counts** of layers scoring 1–3, 4–6, 7–10. Must sum with `N_NA` to 23 |
| `{{TIER_NOTE}}` | e.g. ` · scored as a live app taking payments` — or delete |
| `{{GATE_DETAIL}}` | **Gate failed** (keep `.gate.fail`): which gates failed and why, one sentence, with `file:line`. **All gates passed** (keep `.gate.pass`): name the lowest-scoring gate, e.g. "Every gate layer scores 4 or more. Security is the closest call at 4/10." |
| `{{SEVERITY_COUNTS}}` | e.g. `3 critical · 2 high` |
| `{{SCOPE_NOTE}}` | Any limit on what you read, and how the review was split (e.g. "Reviewed in 4 parallel tasks; gate findings re-checked by hand") — or delete the line |
| `{{PREV_DATE}}` `{{PREV_PCT}}` | The earlier report's date and percentage |
| `{{PREV_SUMMARY}}` | Delta, how many earlier problems are fixed / partly / not fixed, and any layer that went **down**. If the earlier report used different layers, say the percentages are not directly comparable |
| `{{PREV_PATH}}` | Where the earlier report lives in the project |

### The dial

`stroke-dasharray="{{RING_FILLED}} 364.4"` — the circle's circumference is 364.4
(r=58). So 45% → `164`. Get this right; a wrong arc undermines the report at a
glance.

### The distribution bar

The `flex:` values are the raw **counts**, not percentages — the browser sizes
the segments proportionally. Delete any band whose count is zero, both the bar
segment and its key entry.

---

## Repeatable blocks

**Strengths** — 3 to 5, each with real evidence. This section exists because a
report opening with twenty failures gets closed. Never fabricate one.

**Layer rows** — one per layer, all 23, in numeric order. Two shapes:

*Scored:* meter class `m-ok` (7–10) / `m-warn` (4–6) / `m-bad` (1–3), matching
score class `s-ok` / `s-warn` / `s-bad`, and **bar width = score × 10%** (a 7
becomes `width:70%`). Add `<span class="g-dot" title="Gate layer"></span>` after
the name on gate layers only.

*N/A:* the `.lyr.na` variant, with `{{NA_REASON}}` giving the reason in two or
three words (`serverless`, `no AI features`, `desk-only`).

**Findings** — one per real problem, worst first. `crit` for gate failures and
🔴 layers, `high` for 🟡.

- `{{SEVERITY}}` — "Critical" / "High" (pill `bad`), "Medium" (pill `warn`), "Low"
- `{{EFFORT}}` — "Low effort" / "Medium effort" / "High effort"
- `{{PROMPT_ID}}` — a unique id per finding: `p1`, `p2`, `p3`… It must match
  between the `<pre id>` and the button's `data-copy`, or the copy button does
  nothing

**Quick wins** — 2 or 3, under an hour each. `{{WIN_TIME}}` is the marker, e.g.
`20m`. For a non-developer this is the most valuable section.

**Since the last audit** — only when Phase 1 found an earlier report. If
there is none, delete the whole section.

**Priority order** — from `scoring.md`, reduced to what actually applies.

---

## Writing the fix prompts

**Every finding gets one.** This is what turns the report from a list of
problems into something the reader can act on — they copy it, paste it into
Claude Code or ChatGPT, and get the fix done. For a non-developer it is the
whole value of the report.

Write each prompt so it works **pasted into a fresh session with no context**.
The assistant on the other end has not seen your report and cannot see this
page.

### Structure

```
<One sentence naming the problem and the exact file:line.>

Requirements:
- <what to change>
- <constraints: keep existing API contracts, scope of files>
- <what must never happen: logging secrets, deleting data>

When you are done, walk me through verifying it, and run what you can yourself:
1. <a concrete check with an expected result>
2. <…>
…

Report which of these you ran and which I need to run myself.
```

### Rules

- **Name the real file and line** from your finding. A prompt saying "find where
  passwords are hashed" wastes the first half of the session.
- **State the constraints.** At minimum: do not change unrelated files, keep the
  existing API contract, never log secrets. Without these an assistant will
  happily refactor half the project.
- **Verification steps are not optional.** Each one needs an expected result, so
  the reader can tell pass from fail without judgement. "Confirm the stored hash
  starts with `$2b$`" is checkable; "confirm it is secure" is not.
- **Cover the migration case.** Where existing data is affected — old password
  hashes, existing records without audit rows — say so and ask for the
  transitional path. This is the step most often missed.
- **Forbid destructive actions explicitly** when the fix touches production
  data: *"Do NOT delete anything from the production database"*, *"list them so
  I can decide; do not remove any yourself."*
- **Ask it to report what it ran.** An assistant that silently skips the checks
  looks identical to one that passed them.
- **Never put a secret value in a prompt.** The same rule as the rest of the
  report — name the location only.
- Write them in the user's register. The person pasting this may not know what
  bcrypt is; the assistant receiving it does. Say what outcome you want, not how
  to implement it.
- Aim for 12–25 lines. Long enough to be unambiguous, short enough to read
  before pasting.

---

## Writing style for the report

The reader may not write code.

- **What** — the problem in one sentence, no jargon: *"Anyone can try passwords
  on your login page as many times as they like."*
- **Why it matters** — the real consequence: *"An attacker can run through
  common passwords automatically until one works."*
- **Effort** — honest, not optimistic

Never write "simply" or "just". Name a technology only when the reader needs it
to act.

## Never put in the report

- **A secret value.** Write *"a credential appears at `src/config.js:14`"* and
  nothing more. Not the value, not a masked version, not the first four
  characters. The report is built to be shared
- Full file contents or long code dumps from their project
- Personal data found in seed files, fixtures or test records
- Internal hostnames, connection strings or private URLs
- A finding you did not verify by reading the file

## Final chat message

Three lines, then the link. Do not paste the report into chat.

```
Score: 45% (19 of 23 layers applicable)
Verdict: Not production ready — four gate layers failed
Start here: install error tracking (about 20 minutes)
```

Mention that each finding carries a copy-paste fix prompt. Then offer, in one
line, to work through the top item together. Do not start fixing anything
unless they ask.
