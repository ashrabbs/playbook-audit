#!/usr/bin/env bash
# find-projects.sh — locate candidate projects on this machine.
# Read-only. Prints one TAB-separated row per candidate:
#   path <TAB> marker-files <TAB> days-since-modified
#
# Usage: find-projects.sh [start-dir]
#   With no argument, searches the usual places a project lives.

set -uo pipefail

MARKERS=(
  package.json requirements.txt pyproject.toml Pipfile go.mod Cargo.toml
  composer.json Gemfile pubspec.yaml build.gradle build.gradle.kts pom.xml
  Package.swift mix.exs deno.json wrangler.toml wrangler.jsonc
)

PRUNE_DIRS=(
  node_modules .git vendor dist build .next .nuxt target
  __pycache__ .venv venv .cache Library Applications
)

is_project() {
  local dir="$1"
  for m in "${MARKERS[@]}"; do
    [ -e "$dir/$m" ] && return 0
  done
  [ -d "$dir/.git" ] && return 0
  return 1
}

markers_in() {
  local dir="$1" found=()
  for m in "${MARKERS[@]}"; do
    [ -e "$dir/$m" ] && found+=("$m")
  done
  [ -d "$dir/.git" ] && found+=(".git")
  if [ ${#found[@]} -eq 0 ]; then printf -- '-'; else printf '%s' "$(IFS=,; echo "${found[*]}")"; fi
}

days_since() {
  local dir="$1" newest now
  newest=$(find "$dir" -maxdepth 2 -type f \
    \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' \
       -o -name '*.rb' -o -name '*.php' -o -name '*.rs' -o -name '*.java' \
       -o -name '*.json' -o -name '*.md' -o -name '*.html' \) \
    -newermt '1970-01-01' -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
  [ -z "$newest" ] && { printf -- '-'; return; }
  now=$(date +%s)
  printf '%d' $(( (now - ${newest%.*}) / 86400 ))
}

emit() {
  local dir="$1"
  dir="${dir%/}"
  printf '%s\t%s\t%s\n' "$dir" "$(markers_in "$dir")" "$(days_since "$dir")"
}

# --- 1. Explicit directory argument -----------------------------------------
if [ $# -ge 1 ] && [ -d "$1" ]; then
  START="$(cd "$1" && pwd)"
  if is_project "$START"; then emit "$START"; exit 0; fi
  SEARCH_ROOTS=("$START")
else
  # --- 2. Current directory, then its git root ------------------------------
  CWD="$(pwd)"
  if is_project "$CWD"; then emit "$CWD"; exit 0; fi
  GITROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)"
  if [ -n "$GITROOT" ] && is_project "$GITROOT"; then emit "$GITROOT"; exit 0; fi

  # --- 3. The usual places --------------------------------------------------
  SEARCH_ROOTS=(
    "$HOME/projects" "$HOME/Projects" "$HOME/code" "$HOME/Code"
    "$HOME/dev" "$HOME/Dev" "$HOME/src" "$HOME/repos" "$HOME/git"
    "$HOME/Documents" "$HOME/Desktop" "$HOME/Sites" "$HOME/workspace"
  )
fi

# --- Search ------------------------------------------------------------------
prune_expr=()
for d in "${PRUNE_DIRS[@]}"; do
  prune_expr+=( -name "$d" -o )
done
unset 'prune_expr[${#prune_expr[@]}-1]'

for root in "${SEARCH_ROOTS[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r dir; do
    [ -n "$dir" ] && is_project "$dir" && emit "$dir"
  done < <(
    find "$root" -maxdepth 3 \
      \( \( "${prune_expr[@]}" \) -prune \) -o -type d -print 2>/dev/null
  )
done | sort -u -t$'\t' -k1,1
