#!/usr/bin/env bash
set -euo pipefail

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree isn't clean. Commit or stash first." >&2
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "main" ]; then
  echo "You're on '$branch', not main. Releases are cut from main." >&2
  exit 1
fi

git fetch origin main --tags --quiet
if ! git merge-base --is-ancestor HEAD origin/main; then
  echo "Local main is behind origin/main. Pull first." >&2
  exit 1
fi

latest=$(git tag --list 'v*.*.*' --sort=-v:refname | head -1)
latest="${latest:-v0.0.0}"
version="${latest#v}"
IFS='.' read -r major minor patch <<< "${version%%-*}"

echo "Latest tag: $latest"
echo
echo "1) patch  -> v$major.$minor.$((patch + 1))"
echo "2) minor  -> v$major.$((minor + 1)).0"
echo "3) major  -> v$((major + 1)).0.0"
echo "4) custom (e.g. a -beta.N prerelease)"
read -rp "Bump [1-4]: " choice

case "$choice" in
  1) next="v$major.$minor.$((patch + 1))" ;;
  2) next="v$major.$((minor + 1)).0" ;;
  3) next="v$((major + 1)).0.0" ;;
  4) read -rp "Tag: " next ;;
  *) echo "Unknown choice." >&2; exit 1 ;;
esac

if [[ ! "$next" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-.+)?$ ]]; then
  echo "'$next' doesn't look like vX.Y.Z or vX.Y.Z-suffix." >&2
  exit 1
fi

if git rev-parse "$next" >/dev/null 2>&1; then
  echo "Tag $next already exists." >&2
  exit 1
fi

if [[ "$next" == *-* ]]; then
  echo "$next will publish as a prerelease."
fi

read -rp "Tag and push $next? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

git tag "$next"
git push origin "$next"

echo "Pushed $next. Follow the release: gh run watch -R jelly-terminal/jelly"
