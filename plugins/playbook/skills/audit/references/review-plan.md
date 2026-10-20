# Review Plan — Splitting the Audit into Smaller Tasks

Twenty-three layers is too much to hold in your head at once on a real
codebase. Scores drift, evidence gets vague, and the last layers get a fraction
of the attention the first ones did. So split the review into smaller tasks,
each covering a handful of layers, and give every task the same instructions
and the same output format.

---

## 1. Measure the project

Run the bundled counter:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/count-lines.sh <project-dir>
```

It prints one number: lines of source code, ignoring dependencies, build output
and lockfiles.

## 2. Pick the plan

| Source lines | Plan |
|---|---|
| Under 3,000 | **Single pass.** Do all layers yourself, in order. Splitting costs more than it saves |
| 3,000 – 50,000 | **Standard: 4 review tasks** (table A below) |
| Over 50,000 | **Deep: 8 review tasks** (table B below) — but ask first, see below |

**Before a deep review, ask.** Eight tasks read more code and use more of the
user's plan allowance. Ask once with `AskUserQuestion`:

> This is a large project. How thorough should the review be?
> 1. **Standard — 4 reviews** (Recommended). Covers every layer; the usual choice.
> 2. **Deep — 8 smaller reviews.** Finds more, takes longer, and uses more of
>    your plan's usage. Best on Pro plans and above with room to spare.

If the user asks for a deeper or more thorough audit at any size, use plan B
without asking. If they are on a plan with tight limits or say usage matters,
stay on plan A.

## 3. Run the tasks

**If you have the `Agent` tool:** start every task as its own subagent, all in
one message so they run at the same time. Paste the task prompt (section 5)
into each, with its layers filled in.

**If you do not have the `Agent` tool:** do the tasks yourself, **one at a
time**. After each task, write its results to a notes file outside the project
(the same temporary folder the report goes in, e.g.
`<tmp>/audit-notes-task-1.md`), then start the next task fresh by re-reading
only the layers it covers. Never try to remember earlier tasks — read your
notes files back when you build the report.

## Table A — Standard: 4 review tasks

| Task | Layers | Theme |
|---|---|---|
| A1 | 3, 4 🚪, 8 🚪 | Data, sign-in and security |
| A2 | 1, 2, 9, 10, 11, 14 | Frontend, API, limits and scale |
| A3 | 5, 6, 7, 12 🚪, 13 🚪, 15, 17 | Deploy, monitoring, recovery, docs, tests |
| A4 | 16, 18, 19, 20, 21, 22, 23 | Legal, time, offline, records, accessibility, presentation |

## Table B — Deep: 8 review tasks

| Task | Layers | Theme |
|---|---|---|
| B1 | 4 🚪 | Sign-in and permissions — including "can user A see user B's data?" |
| B2 | 8 🚪 | Security — including the full git history for secrets |
| B3 | 2, 3 | API and database |
| B4 | 1, 21 | Frontend, unhappy path and accessibility |
| B5 | 5, 6, 7 | Hosting, cloud and CI/CD |
| B6 | 12 🚪, 13 🚪 | Error tracking, backups and recovery |
| B7 | 9, 10, 11, 14, 18, 19 | Limits, caching, scale, AI, time, offline |
| B8 | 15, 16, 17, 20, 22, 23 | Docs, legal, testing, audit trail, presentation, marketing |

Layers already marked N/A in Phase 1 are dropped from their task. If a task
ends up empty, skip it.

## 4. Check the claims that decide the verdict

Reviewers make mistakes. Before scoring, **open and read the cited lines
yourself** for:

- Every gate layer scoring 1–3 (it decides "not production ready")
- Every finding you will mark Critical
- Every N/A — check it against the N/A rules in `discovery.md`. Reviewers tend
  to mark layers N/A too readily

If a citation does not say what the reviewer claimed, fix the score or drop
the finding.

Write the check down. In your notes file, one row per item above:
`claim | file:line | what the line actually shows | ✅ / ❌`. Open every line
yourself; a reviewer's line number is a pointer, not proof. Do not start the
report until every row is filled. A Critical finding with no ✅ row does not
go in the report.

Then merge the results. Each task returns an **Outside my layers** list: fold
every line into the layer it belongs to, and score it there once. Do not score
the same problem in two layers — in the test run source maps were reported
three times. Continue with `scoring.md`.

## 5. The task prompt

Fill in the `<...>` parts. Use it word for word otherwise — the rules and the
output format are what keep every task's results consistent.

```
You are one reviewer in a READ-ONLY production-readiness audit of the project at
<project-dir>. It is <one-line fingerprint from Phase 1>.

Rules — not negotiable:
- Do not create, edit or delete any file in the project. Do not run the
  project's code, tests, installs or scripts. Read-only git commands are fine,
  and so is `npm audit --package-lock-only` (or the stack's equivalent). Make
  no other network calls.
- Stay inside your layers. If you notice a problem in another layer, list it
  in one line under "Outside my layers" and do not investigate it.
- Never print a secret value, not even partly. Write only "a credential appears
  at file:line".
- Every score cites a real file:line you actually read. If you can't find
  something, say "not found" and score low. Never assume.

Your layers: <numbers and names>.
Read their checks in <skill-dir>/references/layers.md and the scale in
<skill-dir>/references/scoring.md (1-10; 7-10 green, 4-6 amber, 1-3 red).
Context: <tier from discovery.md §6, who uses it and where, payments live or not>.
<If your layers include 18 or 20:> Say whether each is a gate for this
project, using the conditions in scoring.md, and why.
<If a previous report exists:> A previous audit is at <path>. For each issue it
raised in your layers, say whether it is fixed, not fixed or partly fixed,
with file:line. <If it used different layers:> Its layers map to ours as
<old → new, from the mapping you worked out when you read that report in
Phase 1>; check each issue under the layer it now belongs to.

Return exactly this, for each layer:

### Layer <n> — <name>: <score>/10 (or N/A — <reason>)
Why: <one sentence>
Evidence: <2-4 file:line citations>
Findings:
- What: <plain English, no jargon> | Why it matters: <consequence> |
  Fix: <specific change and file> | Effort: Low/Medium/High |
  Severity: Critical/High/Medium/Low
Previous items: <fixed ✅ / not fixed ❌ / partly ⚠️ — file:line, or "none">
Outside my layers: <one line per problem seen elsewhere, with file:line, or "none">

Then: Strengths — 1 to 3 things done well, each with file:line.
Be honest. Don't inflate scores and don't invent findings. Under 1,000 words.
```
