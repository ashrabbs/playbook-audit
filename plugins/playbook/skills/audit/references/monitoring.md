# Monitoring — Better Stack

Layer 12's discovery question is *"if this went down right now, how would you
find out?"* The code alone can't fully answer it: an uptime monitor lives
outside the repo. This file covers the tool the audit recommends for that gap,
and how to check it live when it's connected.

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
