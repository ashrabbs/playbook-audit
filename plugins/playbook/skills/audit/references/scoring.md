# Scoring

## Per-layer scale

| Score | Meaning |
|---|---|
| **9–10** | Best practice, no obvious gaps |
| **7–8** | Solid, minor improvements possible |
| **5–6** | Partial — important gaps present |
| **3–4** | Minimal, significant risk |
| **1–2** | Not implemented, or critically broken |
| **N/A** | Genuinely does not apply — and you say why |

Status: 🟢 7–10 · 🟡 4–6 · 🔴 1–3

**Every score cites a `file:line` you actually read.** A score without evidence
is an opinion, and opinions drift upward. If you could not find something,
score it low and write "not found" — never assume it exists because it usually
does.

---

## The percentage

```
applicable = 10 × (number of layers scored, excluding N/A)
percentage = round(100 × earned / applicable)
```

**Always report the percentage, never a bare total.** N/A layers are excluded
from the denominator, so a raw number is meaningless on its own — 119/140 and
119/230 are not the same project. Report it as:

> **68%** — 95 of 140 points across 14 applicable layers (9 marked N/A)

List which layers were excluded and why. A reader who disagrees with an N/A can
then say so.

## Bands

| Band | Verdict |
|---|---|
| **80–100%** | Production ready |
| **60–79%** | Close — fix the critical gaps first |
| **38–59%** | Not production ready |
| **Below 38%** | Demo-grade only |

## The gate rule — this overrides the band

| Gate layer | Always, or conditional |
|---|---|
| 4 — Auth and Permissions | Always (unless the layer is N/A) |
| 8 — Security | Always |
| 12 — Error Tracking and Logs | Always |
| 13 — Availability and Recovery | Always |
| 18 — Time and Scheduling | When the app reasons about dates/shifts/schedules |
| 20 — Audit Trail | When the app is a record of truth |

**A 🔴 (1–3) in any gate layer means NOT PRODUCTION READY, whatever the
percentage says.** State this at the top of the report when it happens.

### Hard caps on gate layers

Apply these before any judgement. A gate layer that meets a cap scores at most
3, however much else is in place:

- **12** — no uptime check or alert outside the app itself (the discovery
  question's answer is "a user would tell me")
- **13** — no backup stored apart from the primary database, or no restore
  ever practised
- **4** — any endpoint returns another user's data, or passwords are stored
  unhashed
- **8** — a live secret in the repository or its git history

A gate layer scored 4 must name the cap it clears and cite the file:line that
proves it. If you cannot, it is a 3.

A high average must never launder a critical failure. 10/10 caching does not
offset 3/10 authentication — one of those loses user data.

If a gate layer fails, the verdict line reads:

> **Not production ready** — authentication scored 2/10 (passwords stored
> unhashed, `src/auth.js:31`). Overall score 74%, but this one issue blocks
> launch on its own.

## Comparability

A percentage is comparable **to the same project's previous audits**, not across
different projects — two projects with different N/A sets are measured on
different scales. Say this in the report so nobody treats the number as a
leaderboard position.

Phase 1 of `SKILL.md` searches the project for an earlier report. If one
exists, record:

- Previous score and date
- Delta (+/- points)
- Any layer that went **down** — a regression is more important than the
  headline number. A score that changed while the code at the cited lines did
  not is drift, not a regression; say so
- Each earlier problem: fixed ✅ / not fixed ❌ / partly fixed ⚠️, with `file:line`

If the earlier report used a different set of layers (an older version of
this playbook, or another reviewer's checklist), its percentage is on a
different scale: say so, skip the delta, and still check its problems one by
one. That check is what the reader wants to know.

## Fix verification

If the user says gaps from a previous audit have been fixed, verify each one
before crediting it:

- **Claim** — what was reported fixed
- **Verified?** ✅ confirmed at `file:line` / ❌ not actually fixed / ⚠️ partial

A fix nobody re-tested is a fix that might not exist. Never take "done" on
trust.

## Priority order for the recommendations section

1. **Gate-layer 🔴s** — nothing else matters until these clear
2. Observability and recovery (12, 13) — you cannot fix what you cannot see
3. Security (8)
4. Auth and data isolation (4)
5. Record integrity (20), if a record of truth
6. Correctness of "when" (18), if time-critical
7. Reliability and the unhappy path (1, 2, 9)
8. Test coverage on the critical path (17) — before any refactor, not after
9. Field resilience (19), if used on poor connectivity
10. Performance and scale (3, 10, 11)
11. Accessibility (21) — legal exposure, not polish
12. Presentation (22), legal and docs (15, 16)

## Quick wins

Pick 2–3 fixes that take under an hour and have real impact. For a
non-developer this is the most valuable section in the whole report — it is
where they start. Each needs the specific file and the specific change.

## Honesty rules

- If the project is in good shape, say so plainly. Do not manufacture findings
  to look thorough
- If you could not assess something, mark it "not assessed" rather than guessing
  a score
- If the codebase was too large to read exhaustively, say what you did read:
  *"Scored from the 40 files most relevant to each layer; a deeper pass may find
  more"*
- Never inflate a score because the person seems invested in the project
