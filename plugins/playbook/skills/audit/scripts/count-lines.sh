#!/usr/bin/env bash
# count-lines.sh — count lines of source code in a project, to size the review.
# Read-only. Prints a single number.
#
# Usage: count-lines.sh [project-dir]

set -uo pipefail

DIR="${1:-.}"
[ -d "$DIR" ] || { echo "Not a directory: $DIR" >&2; exit 1; }

find "$DIR" \
  \( -name node_modules -o -name .git -o -name vendor -o -name dist -o -name build \
     -o -name .next -o -name .nuxt -o -name target -o -name __pycache__ \
     -o -name .venv -o -name venv -o -name .cache -o -name coverage \) -prune -o \
  -type f \( -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \
     -o -name '*.ts' -o -name '*.tsx' -o -name '*.vue' -o -name '*.svelte' \
     -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.php' \
     -o -name '*.java' -o -name '*.kt' -o -name '*.swift' -o -name '*.dart' \
     -o -name '*.cs' -o -name '*.ex' -o -name '*.exs' -o -name '*.sql' \
     -o -name '*.html' -o -name '*.css' -o -name '*.scss' \) \
  ! -name '*.min.*' -print0 2>/dev/null \
  | xargs -0 cat 2>/dev/null | wc -l | tr -d ' '
