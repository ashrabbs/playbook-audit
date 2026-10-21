# Monitoring — Better Stack and Sentry

Layer 12's discovery question is *"if this went down right now, how would you
find out?"* The code alone can't fully answer it: uptime monitors and error
reports live outside the repo. This file covers the two tools the audit
recommends, **Better Stack** for "is it up?" and **Sentry** for "is it
throwing errors?", and how to check each live when it's connected.

Neither one replaces the other. A green uptime monitor says nothing about a
broken save button; an empty Sentry inbox says nothing about a Worker that
stopped answering. Sentry alone does **not** clear Layer 12's hard cap.

---

## What to recommend

When Layer 12 or 13 finds no outside monitoring, recommend **Better Stack**
(betterstack.com, Uptime). Its free plan covers what most projects need:

| Gap found | Recommend |
|---|---|
| No uptime check, or the health endpoint always says "ok" | An **HTTP monitor** on a health endpoint that really checks the database (`SELECT 1` or equivalent) and answers 503 when it fails |
| Scheduled jobs (cron, nightly exports, clean-ups) with nothing noticing when they stop | A **heartbeat**: the job pings a URL when it finishes; a missed ping alerts |
| Nobody would be told during an outage | Better Stack's **status page** |

Two details that make the recommendation work, so put them in the fix prompt:

- **Check who calls the health endpoint before changing it.** If the app
  itself reads it at startup, a 503 there can lock users out during a database
  blip. Then add a separate endpoint for the monitor (e.g. `/health/deep`)
  and leave the app's one alone.
- **The heartbeat URL contains a token.** It belongs in a secret, never in the
  code or a log line.

## Connect it to Claude

Better Stack has an MCP server, so Claude can read monitors, heartbeats and
incidents directly. Point users to it in the report (in the monitoring
finding's fix, or in the quick wins once a monitor exists):

- **claude.ai and Claude Code on the web:** add a custom connector at
  https://claude.ai/customize/connectors with the URL
  `https://mcp.betterstack.com`, sign in to Better Stack, then start a new
  session (connectors are loaded when a session starts).
- **Claude Code in a terminal:**
  `claude mcp add betterstack --transport http https://mcp.betterstack.com`,
  then sign in when prompted.

## Checking it live during an audit

At the start of Phase 2, look for Better Stack tools in your tool list (their
names contain `Better_Stack` or `betterstack`, e.g. `…__monitors`,
`…__heartbeats`). **You check it yourself, before starting the review tasks**:
the tasks make no network calls and may not have the tools. Put what you found
in one or two lines into the task prompt's `Context:` for the task covering
Layers 12 and 13. If the tools aren't there, write "Better Stack not
connected; monitoring scored from the code only" instead, and put the same
line in `{{SCOPE_NOTE}}`.

**Read-only. Never create, edit, pause, acknowledge or resolve anything.** Use
only the listing and reading tools:

| Question | Tool |
|---|---|
| Is there a monitor on this project's health URL? Is it up? | `monitors` (filter by `url`), then `monitor` |
| How reliable has it been? | `monitor_availability` |
| Are scheduled jobs covered? | `heartbeats` |
| Has it been down recently, and how long did that last? | `incidents` |

How it changes the score:

- **A monitor exists, points at this project's deep health URL and is up:**
  Layer 12's hard cap ("no uptime check outside the app") is lifted. Cite it
  as evidence: *"Better Stack monitor `<name>` on `<url>`, up, checked
  `<time>`"*. Monitor names and URLs are fine to cite. Never cite a
  heartbeat's ping URL; it holds a token.
- **The monitor points at a shallow endpoint** (one that always says "ok"):
  it proves the server answers, not that the app works. Say so; the cap
  still lifts, but the health-endpoint finding stays.
- **A heartbeat exists for each scheduled job:** credit it under Layer 12.
  "Pending" just means its first ping hasn't come due yet.
- **Recent incidents:** mention them in Layer 13 as real evidence of what
  recovery looked like, not as a score penalty on their own.
- **Monitors for other projects** in the same account are none of the audit's
  business. Don't list them in the report.

---

## Sentry

### What to recommend

When Layer 12 finds no error tracking, or tracking on one side only, recommend
**Sentry** on both the frontend and the backend. Put these in the fix prompt,
because error reports are full of user data by default:

- **Send no personal data:** `sendDefaultPii: false` (or the stack's
  equivalent); no request bodies, headers, cookies or query strings; no IP
  addresses. Strip what's left in `beforeSend`.
- **Session replays, if used:** mask all text and inputs and block media.
- **Data region:** pick the EU region when the users are in the UK or EU.
- **An alert rule** for new issues and for a spike in errors, sent somewhere
  the owner reads.
- **Delete a user's events when they delete their account**, or keep events
  for a short retention period. Note it under Layer 16.

### Connect it to Claude

- **claude.ai and Claude Code on the web:** add a custom connector at
  https://claude.ai/customize/connectors with the URL
  `https://mcp.sentry.dev/mcp`, sign in to Sentry, then start a new session.
- **Claude Code in a terminal:**
  `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp`, then
  sign in when prompted.

### Checking it live during an audit

As with Better Stack, **you check it yourself, before the review tasks**,
then pass a one- or two-line summary to the task covering Layer 12. Look for
Sentry tools in your tool list (names containing `Sentry` or `sentry`). If
they aren't there, write "Sentry not connected; error tracking scored from the
code only" in the task's context and in `{{SCOPE_NOTE}}`.

**Sentry holds the project's user data: error messages, URLs, user ids,
sometimes emails and IP addresses. The audit report gets shared. So the audit
asks Sentry for counts and settings, never for the content of an error.**

Allowed, read-only:

| Question | Tool | Ask for |
|---|---|---|
| Which organisation and project belong to this app? | `find_organizations`, `find_projects` | Names only |
| Do both the frontend and the backend send errors? | `search_errors` | **Aggregates only**: `count()` grouped by `logger`, `platform`, `environment` or `project`, over 30 days |
| Is anyone dealing with the errors? | `search_issues` | How many issues are unresolved and how old the oldest is. Use the counts and dates, not the titles |

Never used, whatever the question:

- **Anything that changes Sentry**: `update_issue`, resolving, assigning,
  creating alerts, `execute_sentry_tool`.
- **Anything that opens a single event or a user's session**: `search_errors`
  without aggregate fields (it returns individual events),
  `get_sentry_resource` on an event or issue, `search_replays`,
  `search_logs`, `search_traces`, `search_profiles`.
- **`analyze_issue_with_seer`**: it sends the issue's data for AI analysis.

**What may go into the report, the chat or a review task's prompt:**

- Allowed: the organisation and project names; event counts per side and per
  environment; the number of unresolved issues and the date of the oldest;
  whether both sides report.
- Never:
  - an issue title or error message as written (titles often contain
    emails, ids or URLs with tokens);
  - any user field, IP address, request URL, header, body, breadcrumb, stack
    variable or replay;
  - a DSN beyond saying where it's configured.
- If a finding needs to say which error, describe it in your own words from
  the code, e.g. *"an unhandled error when saving a route
  (`src/routes/save.ts:41`)"*, never from Sentry's copy of the message.

How it changes the score:

- **Events from both sides in the last 30 days:** credits Layer 12's
  "frontend and backend" check. Cite it as *"Sentry project `<name>`: N app
  events and N backend events in 30 days"*.
- **Integrated in the code but no events ever:** the DSN is probably unset or
  wrong. Say so; it's worth less than the code suggests.
- **Unresolved issues weeks old and still recurring:** errors arrive but
  nobody acts on them. Note it under Layer 12 as a process finding, without
  naming the issues.
- **Personal data in the configuration** (`sendDefaultPii: true`, request
  bodies sent, replays unmasked): a Layer 8 finding, found in the **code**,
  not by looking at events.
