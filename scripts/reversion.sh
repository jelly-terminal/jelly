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

git fetch origin main --tags --force --quiet
if ! git merge-base --is-ancestor HEAD origin/main; then
  echo "HEAD isn't on origin/main. Push main first." >&2
  exit 1
fi

tag=$(git tag --list 'v*.*.*' --sort=-v:refname | head -1)
if [ -z "$tag" ]; then
  echo "No release tag to redo." >&2
  exit 1
fi

if gh release view "$tag" -R jelly-terminal/jelly >/dev/null 2>&1; then
  echo "A GitHub release for $tag already exists. Delete it first or cut a new version." >&2
  exit 1
fi

old=$(git rev-parse --short "$tag^{commit}")
new=$(git rev-parse --short HEAD)

echo "Tag:  $tag"
echo "From: $old $(git log -1 --format=%s "$tag")"
echo "To:   $new $(git log -1 --format=%s HEAD)"
echo
git log --oneline "$tag..HEAD"
echo

read -rp "Delete remote $tag, retag at $new and push? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

git push origin ":refs/tags/$tag"
git tag -d "$tag" >/dev/null
git tag "$tag"
git push origin "$tag"

echo "Re-pushed $tag. Follow the release: gh run watch -R jelly-terminal/jelly"
