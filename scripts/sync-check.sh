#!/usr/bin/env bash
# sync-check.sh — report drift between the private Playbook and this public skill.
#
# The public audit skill is derived from the private Playbook repo. The two are
# deliberately NOT byte-identical: layers.md is the stack-agnostic rewrite of
# audit_enhanced.md, with the Cloudflare/Crewly specifics moved to an appendix.
#
# So this does not diff them. It tells you whether the private source has moved
# since the last sync, so you can decide what needs carrying across by hand.
#
# Usage: ./scripts/sync-check.sh [path-to-private-Playbook]

set -euo pipefail

PLAYBOOK="${1:-$HOME/Projects/Playbook}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$HERE/.last-sync"

if [ ! -d "$PLAYBOOK/.git" ]; then
  echo "Private Playbook not found at: $PLAYBOOK"
  echo "Pass its path as the first argument."
  exit 1
fi

CURRENT=$(git -C "$PLAYBOOK" rev-parse --short HEAD)
echo "Private Playbook HEAD: $CURRENT"

if [ ! -f "$STAMP" ]; then
  echo "No .last-sync stamp yet. Recording $CURRENT as the baseline."
  echo "$CURRENT" > "$STAMP"
  exit 0
fi

LAST=$(cat "$STAMP")
echo "Last synced:           $LAST"

if [ "$CURRENT" = "$LAST" ]; then
  echo
  echo "✔ Up to date — nothing has changed in the private Playbook since the last sync."
  exit 0
fi

echo
echo "Commits to the private Playbook since the last sync:"
echo
git -C "$PLAYBOOK" log --oneline "$LAST..HEAD" -- \
  audit_enhanced.md Production_App_Setup_Playbook.md 2>/dev/null \
  || git -C "$PLAYBOOK" log --oneline "$LAST..HEAD"

echo
echo "Files changed:"
git -C "$PLAYBOOK" diff --stat "$LAST..HEAD" -- \
  audit_enhanced.md Production_App_Setup_Playbook.md 2>/dev/null || true

cat <<'EOF'

Carry across anything that affects the audit itself:
  audit_enhanced.md  →  plugins/playbook/skills/audit/references/layers.md
                        (strip Cloudflare/Crewly specifics into the stack-notes
                         appendix; keep the checks portable)
  scoring changes    →  plugins/playbook/skills/audit/references/scoring.md
  new layers         →  layers.md AND the table in README.md
                        AND the N/A rules in references/discovery.md

Then record the new baseline:
  git -C <playbook> rev-parse --short HEAD > .last-sync
EOF
