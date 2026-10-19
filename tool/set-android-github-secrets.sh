#!/usr/bin/env bash
# Upload Android release signing material to GitHub Actions repository secrets.
# Requires: gh auth login, upload-keystore.jks at repo root (or KEYSTORE_PATH).
#
# Usage:
#   ./tool/set-android-github-secrets.sh
#   KEYSTORE_PATH=/path/to/upload-keystore.jks ./tool/set-android-github-secrets.sh
#
# Non-interactive (passwords via env; avoid shell history):
#   ZEPHYR_KEYSTORE_STORE_PASSWORD=... ZEPHYR_KEYSTORE_KEY_PASSWORD=... \
#     ZEPHYR_KEYSTORE_KEY_ALIAS=upload ./tool/set-android-github-secrets.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE_PATH="${KEYSTORE_PATH:-$ROOT/upload-keystore.jks}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Install GitHub CLI (gh) and run: gh auth login" >&2
  exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "Not logged in. Run: gh auth login -h github.com -p https -w" >&2
  exit 1
fi

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "Keystore not found: $KEYSTORE_PATH" >&2
  exit 1
fi

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "Repository: $repo"
echo "Keystore: $KEYSTORE_PATH"

if [[ -z "${ZEPHYR_KEYSTORE_STORE_PASSWORD:-}" ]]; then
  read -r -s -p "Keystore password (ANDROID_KEYSTORE_PASSWORD): " ZEPHYR_KEYSTORE_STORE_PASSWORD
  echo
fi

if [[ -z "${ZEPHYR_KEYSTORE_KEY_PASSWORD:-}" ]]; then
  read -r -s -p "Key password [Enter = same as keystore] (ANDROID_KEY_PASSWORD): " ZEPHYR_KEYSTORE_KEY_PASSWORD
  echo
  if [[ -z "$ZEPHYR_KEYSTORE_KEY_PASSWORD" ]]; then
    ZEPHYR_KEYSTORE_KEY_PASSWORD="$ZEPHYR_KEYSTORE_STORE_PASSWORD"
  fi
fi

if [[ -z "${ZEPHYR_KEYSTORE_KEY_ALIAS:-}" ]]; then
  echo "Reading key alias from keystore..."
  list_out="$(keytool -list -keystore "$KEYSTORE_PATH" -storepass "$ZEPHYR_KEYSTORE_STORE_PASSWORD" 2>&1)" || {
    echo "$list_out" >&2
    echo "Could not list keystore (wrong store password?)." >&2
    exit 1
  }
  # First PrivateKeyEntry alias line: "myalias, date, PrivateKeyEntry,"
  ZEPHYR_KEYSTORE_KEY_ALIAS="$(echo "$list_out" | awk -F, '/PrivateKeyEntry/ { print $1; exit }' | xargs)"
  if [[ -z "$ZEPHYR_KEYSTORE_KEY_ALIAS" ]]; then
    read -r -p "Key alias (ANDROID_KEY_ALIAS): " ZEPHYR_KEYSTORE_KEY_ALIAS
  else
    echo "Using alias: $ZEPHYR_KEYSTORE_KEY_ALIAS"
  fi
fi

echo "Encoding keystore (single-line base64)..."
if openssl base64 -A -in "$KEYSTORE_PATH" >/tmp/zephyr-keystore.b64 2>/dev/null; then
  :
elif base64 -i "$KEYSTORE_PATH" -b 0 >/tmp/zephyr-keystore.b64 2>/dev/null; then
  :
else
  base64 -i "$KEYSTORE_PATH" | tr -d '\n' >/tmp/zephyr-keystore.b64
fi

echo "Setting GitHub Actions secrets..."
gh secret set ANDROID_KEYSTORE_BASE64 --repo "$repo" --body "$(cat /tmp/zephyr-keystore.b64)"
rm -f /tmp/zephyr-keystore.b64

gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$repo" --body "$ZEPHYR_KEYSTORE_STORE_PASSWORD"
gh secret set ANDROID_KEY_ALIAS --repo "$repo" --body "$ZEPHYR_KEYSTORE_KEY_ALIAS"
gh secret set ANDROID_KEY_PASSWORD --repo "$repo" --body "$ZEPHYR_KEYSTORE_KEY_PASSWORD"

echo "Done. Secrets set on $repo:"
gh secret list --repo "$repo" | grep -E '^ANDROID_' || true
