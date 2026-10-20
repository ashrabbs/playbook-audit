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
| `{{N_BAD}}` `{{N_WARN}}` `{{N_OK}}` | **Counts** of layers scoring 1–3, 4–6, 7–10. Must sum with `N_NA` to 23. These are bands, not severities — the key reads "red / amber / green", because "critical" already counts findings in the findings heading |
| `{{LAYER_NUM}}` | The layer number, 1–23 |
| `{{LAYER_NAME}}` | The layer's name as `layers.md` gives it, e.g. "Auth & Permissions" |
| `{{LAYER_SCORE}}` | The bare number — write `7`, not `7/10`; the grid row appends `/10` itself. In the evidence row for a skipped layer write `N/A` |
| `{{SCORE_PCT}}` | The meter bar width: `LAYER_SCORE × 10`. A 7 gives `width:70%`. Must agree with the score beside it |
| `{{NA_REASON}}` | Why a layer is N/A, in two or three words: `serverless`, `no AI features`, `desk-only` |
| `{{LAYER_WHY}}` | One sentence saying why that layer got that score |
| `{{LAYER_EVIDENCE}}` | The `file:line` behind it. **Required on every scored layer** — this is where the "every score cites a file:line" rule is actually kept |
| `{{TIER_NOTE}}` | e.g. ` · scored as a live app taking payments` — or delete |
| `{{GATE_DETAIL}}` | **Gate failed** (keep `.gate.fail`): which gates failed and why, one sentence, with `file:line`. **All gates passed** (keep `.gate.pass`): name the lowest-scoring gate, e.g. "Every gate layer scores 4 or more. Security is the closest call at 4/10." |
| `{{STRENGTH_TEXT}}` | One thing the project does well, in a sentence. Specific, never generic praise |
| `{{STRENGTH_EVIDENCE}}` | The `file:line` that proves it |
| `{{SEVERITY_COUNTS}}` | e.g. `3 critical · 2 high` |
| `{{FINDING_TITLE}}` | The problem as a short headline in plain English, e.g. "Passwords are stored in a way that can be reversed" |
| `{{FINDING_WHAT}}` | The problem in one sentence, no jargon |
| `{{FINDING_WHY}}` | The real consequence if it is left alone |
| `{{FINDING_LAYER}}` | The layer number this finding belongs to |
| `{{FINDING_EVIDENCE}}` | The `file:line` where you found it. Never the secret itself |
| `{{FIX_PROMPT}}` | The copy-paste prompt for this finding — see **Writing the fix prompts** below |
| `{{SEVERITY}}` | "Critical" / "High" (pill `bad`), "Medium" (pill `warn`), "Low" |
| `{{EFFORT}}` | "Low effort" / "Medium effort" / "High effort" |
| `{{PROMPT_ID}}` | A unique id per finding — `p1`, `p2`, `p3`… It must match between the `<pre id>` and the button's `data-copy`, or the copy button does nothing |
| `{{SCOPE_NOTE}}` | Any limit on what you read, and how the review was split (e.g. "Reviewed in 4 parallel tasks; gate findings re-checked by hand") — or delete the line |
| `{{PREV_DATE}}` `{{PREV_PCT}}` | The earlier report's date and percentage |
| `{{PREV_SUMMARY}}` | Delta (or "not comparable" if the layers differ), the counts of fixed / partly / not fixed, and any layer that went **down**. Count only problems the earlier report actually listed. "Fixed" means fully resolved at the cited line; anything less is partly |
| `{{PREV_PATH}}` | Where the earlier report lives in the project |
| `{{MORE_COUNT}}` | How many findings are in the compact table |
| `{{MORE_WHAT}}` `{{MORE_LAYER}}` `{{MORE_EVIDENCE}}` `{{MORE_EFFORT}}` | One row each: the problem in one line, its layer, its `file:line`, and Low/Medium/High |
| `{{MORE_NOTE}}` | Why these have no fix prompt, e.g. "Below the top 15 by severity. Ask for a fix prompt for any of them." |
| `{{WIN_TITLE}}` | The action, as an instruction: "Install Sentry", "Give development its own database" |
| `{{WIN_DETAIL}}` | Why it is worth doing first, and what it costs |
| `{{WIN_TIME}}` | The time estimate shown as the marker, e.g. `20m`, `45m` |
| `{{PRIORITY_ITEM}}` | One step in the recommended order, as an instruction |
| `{{PRIORITY_NOTE}}` | Which layer it belongs to and why it sits at that point in the order |
| `{{PREV_MARK}}` | ✅ fixed · ⚠️ partly fixed · ❌ not fixed |
| `{{PREV_ITEM}}` | The earlier problem, in one line, as that report described it |
| `{{PREV_EVIDENCE}}` | The `file:line` you checked to decide the mark |

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

**Evidence rows** — the collapsible block under the grid, one row per layer in
numeric order. The grid itself has no room for a citation, so this is where the
scoring rule *"every score cites a real `file:line`"* is actually honoured. In
the test run 7 of 22 scores had no citation anywhere in the published report.

Every **scored** layer needs at least one `file:line`. For an N/A layer the
reason stands on its own and `{{LAYER_EVIDENCE}}` can be dropped. A layer you
could not assess says so here in `{{LAYER_WHY}}` rather than carrying an
invented citation.

**Findings** — worst first, and **capped**. A real audit produces far more
problems than a reader will work through: the test run found about 45, of which
15 got fix prompts and the rest were silently dropped. That choice belongs here,
not to whoever is running out of room.

| Severity | Treatment |
|---|---|
| **Critical** and **High** | A full card with a fix prompt — **up to 15 cards total** |
| Anything beyond the 15th, and every **Medium** / **Low** | One row in the compact table below the cards: What · Layer · `file:line` · Effort. No fix prompt |

If the cap bites, say so under the table: *"18 further findings are listed
below without fix prompts."* Never drop a finding without recording it
somewhere.

Card class: `crit` for gate failures and 🔴 layers, `high` for High, `med` for
Medium and Low (used only when fewer than 15 Critical/High findings exist and
there is room to promote one).

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

**Three lines, then the link, nothing else in between.** Do not paste the
report into chat. The third line is always labelled `Start here:`.

```
Score: 45% (19 of 23 layers applicable)
Verdict: Not production ready — four gate layers failed
Start here: install error tracking (about 20 minutes)
```

Mention that each finding carries a copy-paste fix prompt. Then offer, in one
line, to work through the top item together. Do not start fixing anything
unless they ask.
