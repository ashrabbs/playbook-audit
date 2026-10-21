# Production App Playbook — Audit

A Claude Code plugin that audits any project for production readiness across 23
layers and produces a report you can read and share.

It works out **where your project is** and **what it's built with** on its own.
You don't need to know your tech stack, and you don't need to type a file path.

---

## Run it on the web (claude.ai/code)

No install needed. Plugins can't be installed in a claude.ai/code session, so
the audit is started with one pasted message instead.

1. Open **claude.ai/code** and pick your GitHub repository. You need a Pro,
   Max or Team plan. For a private repository, install the Claude GitHub app
   when it asks.
2. Paste this as your first message:

```
Run a production-readiness audit of this repository.
First clone https://github.com/ashrabbs/playbook-audit into /tmp/playbook (outside this project).
Then follow /tmp/playbook/plugins/playbook/skills/audit/SKILL.md exactly, step by step.
Wherever it says ${CLAUDE_SKILL_DIR}, use /tmp/playbook/plugins/playbook/skills/audit.
Do not change any file in this repository.
```

## Or install it in Claude Code on your computer

Two commands, once, in Claude Code in a terminal:

```
/plugin marketplace add ashrabbs/playbook-audit
/plugin install playbook@playbook-audit
```

Then run:

```
/playbook:audit
```

Either way, it finds your project, tells you what it thinks it is, and produces
a report with a link you can open and share.

### How long it takes

The audit measures your project first. A small one is reviewed in a single
pass. Anything bigger is split into **4 smaller reviews** that run side by side,
so every one of the 23 layers gets proper attention. On a very large project
(over 50,000 lines) it offers a **deep review** in 8 smaller parts. That finds
more but uses more of your plan's usage, so it suits Pro plans and above with
room to spare. You can always ask for the deep review yourself: "do a deep
audit".

You can also just ask, in your own words:

> "is my app ready to launch?"
> "audit this project"
> "what am I missing before I go live?"

---

### Optional: connect Better Stack and Sentry

The audit asks "if your app went down right now, how would you find out?"
Uptime monitors and error reports live outside your code, so the audit can
only check them if Claude can see them. If you use
[Better Stack](https://betterstack.com) or [Sentry](https://sentry.io),
connect them before running the audit:

| | On the web: custom connector at https://claude.ai/customize/connectors | In a terminal |
|---|---|---|
| Better Stack | `https://mcp.betterstack.com` | `claude mcp add betterstack --transport http https://mcp.betterstack.com` |
| Sentry | `https://mcp.sentry.dev/mcp` | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |

After adding a connector on the web, start a new session.

The audit only reads, and never changes anything in either tool. From Better
Stack it reads your monitors, heartbeats and recent incidents. From Sentry it
asks for **counts only** (how many errors, from which side of the app, how
many are unresolved). It never copies an error message, a user's details or
anything else from Sentry into the report, because error reports contain
your users' data and the report is meant to be shared.

Without them, monitoring is scored from the code alone, and the report tells
you how to set them up.

## What you get

A report with:

- **An overall score** out of 100%, and a plain verdict — ready, close, or not yet
- **What the project does well**, with evidence
- **What needs fixing**, each one written as: what the problem is, why it
  matters, how to fix it, and roughly how long it takes
- **Quick wins** — two or three things worth under an hour each. Start here
- **A recommended order** to work through everything else

Scores run 1–10 per layer. Some layers won't apply to your project — a plain
website has no database, a command-line tool has no accessibility layer — and
those are excluded rather than counted against you.

### Critical gaps override the score

Six of the layers are **gates**: authentication, security, error tracking,
backups, and (when they apply) time handling and audit trails. A serious problem
in any one of those means "not production ready" even if the overall percentage
looks healthy. A good average shouldn't hide a problem that loses user data.

---

## The 23 layers

| | | | |
|---|---|---|---|
| 1 Frontend | 7 CI/CD | 13 Availability & Recovery 🚪 | 19 Offline & Sync |
| 2 APIs & Backend | 8 Security 🚪 | 14 AI Pipeline | 20 Audit Trail 🚪* |
| 3 Database & Storage | 9 Rate Limiting | 15 Documentation | 21 Accessibility |
| 4 Auth & Permissions 🚪 | 10 Caching | 16 Legal & Compliance | 22 Share Assets |
| 5 Hosting & Deployment | 11 Load Balancing | 17 Testing | 23 Marketing |
| 6 Cloud & Compute | 12 Error Tracking 🚪 | 18 Time & Scheduling 🚪* | |

🚪 gate layer · \* gate only when it applies to your project

---

## What it will and won't do

**It will:**
- Read your code
- Score it and explain every score with a specific file and line
- Write a report (and its working notes) to files outside your project

**It will not:**
- Change a single file in your project
- Run your code, your tests, or any install or deploy command
- Touch your database
- Put any password, API key or token in the report — it will tell you *where*
  one is, never what it says

It's a read-only review. Nothing it does can break your project.

---

## Updating

```
/plugin marketplace update playbook-audit
```

---

## Troubleshooting

**"/plugin isn't available" or "Unknown command"** — you're probably on
claude.ai/code, where plugins can't be installed. Use the pasted message under
[Run it on the web](#run-it-on-the-web-claudeaicode) instead.

**"Marketplace not found"** — check the spelling: `ashrabbs/playbook-audit`.
You need `git` installed, which you already have if you use Claude Code.

**The install asks about SSH keys** — set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` in
your environment and try again. This repo is public, so it clones over HTTPS
without any credentials.

**It found the wrong project** — tell it. "No, the one in Documents" works fine.

**It says a layer doesn't apply and you think it should** — tell it that too.
The report lists every layer it skipped and why, so you can check its reasoning.

---

## Where this comes from

Distilled from building and running production software, then generalised so it
applies to any stack. The audit is intentionally opinionated: it would rather
tell you something uncomfortable now than let you discover it from a customer.

## Credits

The method here draws on practitioners who publish openly about what actually
breaks in production.

**[Matt Murphy](https://mattmurphy.ai) — The Faction Group.** Several parts of
this audit come directly from his published analysis:

- **The three gaps found in almost every AI-built app**, from a review of
  2,000+ applications — no error handling beyond the default, no environment
  separation, and no audit trail on sensitive actions. These became Layer 1
  (the unhappy path), Layer 5 (environment separation) and Layer 20 (audit
  trail). The framing *"your AI builds the happy path, it never builds the
  unhappy path"* is his, as is *"your AI built the actions, it never built the
  receipts."*
- **The enterprise auth reckoning** in Layer 4 — the four questions a buyer's
  security team asks, the point that your auth provider's compliance is
  effectively your compliance because the buyer audits your whole vendor stack,
  and the case for measuring provider migration cost before you are locked in.
- **MCP as an API discoverability layer** — the argument that API design is
  increasingly about being consumable by AI assistants rather than readable by
  developers.

Also drawn on: OWASP (ASVS and the Cheat Sheet Series), the Twelve-Factor App,
the Google SRE books, and WCAG 2.2.

Attribution here is for influence, not endorsement — none of the people or
organisations named have reviewed this plugin, and any mistakes in how their
ideas are applied are mine.
