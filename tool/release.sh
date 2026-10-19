#!/usr/bin/env bash
# Create release tag vX.Y.Z, bump apps/zephyr pubspec version, push to origin.
# Pushing the tag triggers .github/workflows/release.yml.
#
# Usage:
#   ./tool/release.sh 1.0.4
#   ./tool/release.sh v1.0.4
#   ./tool/release.sh 1.0.4 --dry-run

set -euo pipefail

VERSION_RAW="${1:-}"
DRY_RUN=false
TAG_ONLY=false

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --tag-only) TAG_ONLY=true ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$VERSION_RAW" ]]; then
  echo "Usage: $0 <version> [--dry-run] [--tag-only]" >&2
  exit 1
fi

semver="${VERSION_RAW#v}"
if ! [[ "$semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+([\-+][[:alnum:].\-]+)?$ ]]; then
  echo "Version must look like 1.2.3 (optional -prerelease). Got: $VERSION_RAW" >&2
  exit 1
fi

tag="v${semver}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "main" ]]; then
  echo "Release from main (current branch: $branch)." >&2
  exit 1
fi

upstream="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || true)"
if [[ -z "$upstream" ]]; then
  echo "main has no upstream. Run: git push -u origin main" >&2
  exit 1
fi

behind="$(git rev-list --count "HEAD..@{u}")"
if [[ "$behind" != "0" ]]; then
  echo "main is ${behind} commit(s) behind ${upstream}. Pull first." >&2
  exit 1
fi

pubspec_path="apps/zephyr/pubspec.yaml"
if [[ ! -f "$pubspec_path" ]]; then
  echo "Missing $pubspec_path" >&2
  exit 1
fi

if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1; then
  echo "Tag ${tag} already exists locally." >&2
  exit 1
fi

git fetch --tags origin >/dev/null 2>&1 || true
if git ls-remote --tags origin "refs/tags/${tag}" | grep -q .; then
  echo "Tag ${tag} already exists on origin." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  if [[ "$TAG_ONLY" == true ]]; then
    echo "Warning: working tree has uncommitted changes (--tag-only)." >&2
  else
    echo "Working tree is not clean. Commit or stash first, or use --tag-only." >&2
    exit 1
  fi
fi

commit_message="chore(release): ${tag}"

if [[ "$TAG_ONLY" != true ]]; then
  current_line="$(grep -E '^version:' "$pubspec_path" | head -1)"
  if ! [[ "$current_line" =~ ^version:\ ([0-9]+\.[0-9]+\.[0-9]+)(\+([0-9]+))?$ ]]; then
    echo "Could not parse version line in $pubspec_path" >&2
    exit 1
  fi
  current_name="${BASH_REMATCH[1]}"
  current_build="${BASH_REMATCH[3]:-0}"
  if [[ "$current_name" == "$semver" ]]; then
    new_build=$((current_build + 1))
  else
    new_build=1
  fi
  new_line="version: ${semver}+${new_build}"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] would set $new_line in $pubspec_path"
  else
    sed -i.bak "s/^version: .*/${new_line}/" "$pubspec_path"
    rm -f "${pubspec_path}.bak"
    if ! git diff --quiet -- "$pubspec_path"; then
      git add -- "$pubspec_path"
      git commit -m "$commit_message"
    fi
  fi
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] would tag: ${tag}"
  echo "[dry-run] would push: origin ${branch} and origin ${tag}"
  exit 0
fi

git tag -a "$tag" -m "Zephyr ${tag}"
git push origin "$branch"
git push origin "$tag"

origin_url="$(git remote get-url origin)"
slug=""
if [[ "$origin_url" =~ github\.com[:/](.+?)(\.git)?$ ]]; then
  slug="${BASH_REMATCH[1]}"
fi

echo ""
echo "Done. Watch the Release workflow:"
echo "  https://github.com/${slug}/actions/workflows/release.yml"
