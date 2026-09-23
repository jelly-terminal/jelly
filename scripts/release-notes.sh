#!/usr/bin/env bash
set -euo pipefail

TAG="${1:?usage: release-notes.sh <tag> [previous-tag]}"
PREV="${2:-$(git describe --tags --abbrev=0 --match 'v*' "${TAG}^" 2>/dev/null || true)}"
RANGE="${PREV:+$PREV..}$TAG"
REPO="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url 2>/dev/null | sed -E 's#.*github.com[:/]([^/]+/[^/.]+)(\.git)?#\1#' || true)}"

SECTIONS=(
  "feat|Features"
  "fix|Fixes"
)

format() {
  sed -E 's/^[a-z]+(\(([^)]+)\))?!?: (.)/\2\t\3/' \
    | awk -F'\t' '{
        scope = ""; text = $0
        if (NF > 1) { scope = $1; text = $2 }
        else if (match($0, /^[^\t]/)) { text = $0 }
        first = toupper(substr(text, 1, 1)); rest = substr(text, 2)
        line = "- " (scope != "" ? "**" scope ":** " : "") first rest
        print line
      }'
}

subjects() { git log --no-merges --format=%s "$RANGE" | grep -E "^$1(\([^)]+\))?!?: " || true; }

out=""
breaking=$(git log --no-merges --format=%s "$RANGE" | grep -E '^[a-z]+(\([^)]+\))?!: ' || true)
if [ -n "$breaking" ]; then
  out+=$'### Breaking changes\n\n'"$(printf '%s\n' "$breaking" | format)"$'\n\n'
fi

for section in "${SECTIONS[@]}"; do
  IFS='|' read -r type title <<< "$section"
  list=$(subjects "$type")
  [ -z "$list" ] && continue
  out+="### $title"$'\n\n'"$(printf '%s\n' "$list" | format)"$'\n\n'
done

[ -z "$out" ] && out=$'No user-facing changes.\n\n'

printf '%s' "$out"
if [ -n "$PREV" ]; then
  echo "**Full changelog:** https://github.com/$REPO/compare/$PREV...$TAG"
fi
