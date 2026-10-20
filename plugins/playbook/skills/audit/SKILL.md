---
name: audit
description: Audit a codebase for production readiness across 23 layers and generate a shareable HTML report. Use when asked to audit, review, score or check a project, or for questions like "is this ready for production?", "is this safe to launch?", "what am I missing?", "check my app", "review my code before I ship". Finds the project automatically and adapts to any tech stack.
allowed-tools: Read, Glob, Grep, Write, Artifact, Agent, AskUserQuestion, Bash(git rev-parse *), Bash(git log *), Bash(git status *), Bash(git remote *), Bash(ls *), Bash(find *), Bash(wc *), Bash(bash *)
disallowed-tools: Edit, NotebookEdit
---

# Production Readiness Audit

Audit any project against 23 layers, score it honestly, and produce a report the
user can read and share.

**You are auditing someone else's work, and they may not be a developer.** Be
accurate, be plain-spoken, and never condescend. A finding is only useful if the
person reading it understands what to do next.

> **Where this skill's files are.** `${CLAUDE_SKILL_DIR}` below means the folder
> that contains this `SKILL.md`. If it shows up empty or literally as
> `${CLAUDE_SKILL_DIR}` — for example because the skill was cloned rather than
> installed as a plugin — use that folder's absolute path instead. Every
> `references/…`, `scripts/…` and `assets/…` path is relative to it.

---

## Absolute rules

These are not negotiable. Breaking one makes the audit worse than useless.

1. **Read only. Never modify the project.** No edits, no fixes, no new files in
   their repo, no commits, no installs, no deploys, no database commands. The
   only files you create are the report and your working notes, both written
   outside the project directory.
2. **Never print a secret value.** You will find API keys, tokens and passwords.
   Report them as *"a credential appears at `src/config.js:14`"* — never the
   value itself, not even partially masked. The report gets shared; a leaked key
   in it is a worse outcome than the gap you found.
3. **Never guess.** Every score cites a real `file:line` you actually read. If
   you could not find something, score it low and write "not found" — do not
   assume it exists because it usually does.
4. **Never run their code.** No `npm start`, no test suites, no scripts from the
   project. You are reading, not executing.

---

## Phase 0 — Find the project

Do not ask the user for a file path. Find it, then confirm.

Run the bundled finder:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/find-projects.sh
```

It prints one row per candidate: `path <TAB> markers <TAB> days-since-modified`.

- **One row** → that is almost certainly it. Say what you found in plain
  English and start. Do not make them choose from a list of one.
- **Several rows** → translate each into something a human recognises, then ask
  which one using `AskUserQuestion` so they click instead of typing a path:

  > 1. **holiday-tracker** — a Next.js web app, last changed 2 days ago
  > 2. **invoice-bot** — a Python project, last changed 3 months ago

  Derive the plain-English label from the markers (see
  `references/discovery.md`), never from the raw filenames.
- **No rows** → ask where the project is, and offer the likely reasons: it may
  be somewhere unusual, or on another drive. Accept a path and re-run the finder
  with it as the argument.

**When to ask.** With one row, say what you found and start — do not make them
choose from a list of one. Ask only when there are several rows, when there are
none, or when the user never named a project and the single row might not be
the one they meant. A wasted audit of the wrong project costs more than one
question, but so does a question with one possible answer.

## Phase 1 — Fingerprint the stack

Read `references/discovery.md` and work out:

- Language, framework, package manager
- Hosting / deploy target
- Database, auth, email, payments — present or absent
- CI configuration
- **Which layers are N/A for this project**
- **Whether an earlier audit exists** — see below

The N/A set matters most. A static marketing site has no database layer. A
CLI tool has no accessibility or share-assets layer. Scoring an absent layer as
1/10 produces a dishonest number and a demoralising report.

Tell the user what you detected, in one short paragraph, before you start
scoring. If the fingerprint is wrong they will say so immediately, and you will
have saved the whole audit.

**Send it on its own and wait for a reply before starting the review tasks.**
A fingerprint that goes out in the same message that launches the reviewers
cannot be corrected in time — by the time the user reads it, the audit is
already running on the wrong assumptions.

Two exceptions. If the user has already told you the stack, or has said to go
ahead without checking in, state the fingerprint and continue in the same
message. If you are running unattended, with nobody to answer, do the same and
write the line *"Fingerprint not confirmed with the user"* into `{{SCOPE_NOTE}}`
so the report says which assumptions went unchecked.

Name technologies the user would recognise — the framework, the database, the
host. Leave out library and package names they would have to look up; the
paragraph is there to be corrected, not to prove you read the lockfile.

### Look for an earlier audit

Search the project (skipping `node_modules`, `vendor` and build folders) with
`Glob` for `**/*AUDIT*`, `**/*audit*.md`, `**/*readiness*` and
`**/*Readiness*`. If you find an earlier report — from this skill or any
other review — read its scores and its list of problems. Every review task then
checks each earlier problem: fixed, not fixed or partly fixed, with
`file:line`. The report's "Since the last audit" section shows the result. An
earlier report scored against a different set of layers is still worth
checking problem by problem, but say its percentage is not directly
comparable.

## Phase 2 — Score the layers

**Split the review into smaller tasks first.** Read `references/review-plan.md`
and follow it: measure the project, pick a single pass, 4 review tasks or 8,
run them, then check the claims that decide the verdict yourself. Scoring all
23 layers in one sitting on a real codebase is how scores drift and evidence
gets vague.

Each task reads `references/layers.md`, which holds the checks for all 23
layers, and assigns its layers **1–10, or N/A**.

For each layer record:

- **Score** and status: 🟢 7–10 · 🟡 4–6 · 🔴 1–3
- **Evidence** — a real `file:line`. A score without one is an opinion, and
  opinions drift upward.
- **Findings** — what is wrong, why it matters, and the specific fix

Read actual files. Use `Grep` and `Glob` to find things rather than assuming
conventional paths — the project may not follow any convention you know.

Then read `references/scoring.md` and apply:

- **The gate rule** — a 🔴 in a gate layer means NOT production ready,
  whatever the percentage says
- **Percentage scoring** — N/A layers are excluded from the denominator
- The band, and whether a gate overrides it

## Phase 3 — Build the report

Read `references/report.md`, then fill
`${CLAUDE_SKILL_DIR}/assets/report-template.html`. Use the `Write` tool to
create the filled file — outside the project, never inside it.

Write the finished file to a temporary location **outside the project**, then
publish it with the `Artifact` tool so the user gets a link they can open and
share. If the `Artifact` tool is unavailable, save the HTML next to their home
directory and tell them the full path to open in a browser.

Then, in chat, give them the three-line version:

```
Score: 68% (14 of 23 layers applicable)
Verdict: Not production ready — authentication has a critical gap
Start here: add rate limiting to the login endpoint (about an hour)
```

**Three lines, then the link, nothing else in between.** Do not paste the whole
report into chat; that is what the report is for.

---

## Writing findings for a non-developer

The report is likely to be read by someone who does not write code. Every
finding gets four parts:

| Part | Rule |
|---|---|
| **What** | The problem in one sentence, no jargon. "Anyone can try passwords on your login page as many times as they like." |
| **Why it matters** | The real consequence. "An attacker can guess passwords automatically until one works." |
| **Fix** | The specific first step, with the file. Include a code snippet where it genuinely helps. |
| **Effort** | Low (under an hour) · Medium (a day) · High (more than a day) |

Rules of tone:

- Name the technology only when they need it to act on the finding
- Never say "simply" or "just" — if it were simple it would be done
- Lead the report with what the project does **well**. Three to five specifics,
  with evidence. A report that opens with twenty failures gets closed.
- If the project is in genuinely good shape, say so plainly. Do not manufacture
  findings to look thorough.

---

## Handling a very large project

Splitting into review tasks (`references/review-plan.md`) is the first answer
to size. If even a single task is too big to read exhaustively, do not silently
skim. Prioritise:

1. Gate layers first — auth, security, error tracking, availability
2. Entry points: route handlers, API definitions, config files, CI workflows
3. Anything matching `auth`, `login`, `password`, `admin`, `payment`, `webhook`

Then state the limit in the report: *"Scored from the 40 files most relevant to
each layer; a deeper pass may find more."* An honest partial audit beats a
confident incomplete one.

---

## Reference files

Read these as you reach each phase, not up front:

| File | When |
|---|---|
| `references/discovery.md` | Phase 1 — stack fingerprinting and N/A rules |
| `references/review-plan.md` | Phase 2 — splitting the review into smaller tasks |
| `references/layers.md` | Phase 2 — the 23 layers and their checks |
| `references/scoring.md` | Phase 2 — gates, percentage, bands |
| `references/report.md` | Phase 3 — report structure and how to fill the template |
| `assets/report-template.html` | Phase 3 — the template itself |
