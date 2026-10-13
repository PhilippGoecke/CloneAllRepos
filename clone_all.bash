#!/usr/bin/env bash
# Clone all public repositories of a GitHub user.
# Usage: ./clone_all.bash <github_username> [target_dir]
# Optional: export GITHUB_TOKEN=... to raise rate limits / include private repos (own account).

set -euo pipefail

USER_NAME="${1:-}"
TARGET_DIR="${2:-$USER_NAME}"

if [[ -z "$USER_NAME" ]]; then
  echo "Usage: $0 <github_username> [target_dir]" >&2
  exit 1
fi

for cmd in curl git jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required." >&2; exit 1; }
done

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: token $GITHUB_TOKEN")
fi

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

page=1
per_page=100

while :; do
  response=$(curl -fsSL "${AUTH_HEADER[@]}" \
    "https://api.github.com/users/$USER_NAME/repos?per_page=$per_page&page=$page&type=owner")

  count=$(echo "$response" | jq 'length')
  [[ "$count" -eq 0 ]] && break

  echo "$response" | jq -r '.[] | "\(.name) \(.clone_url)"' | while read -r name url; do
    if [[ -d "$name" ]]; then
      echo "Updating $name..."
      git -C "$name" pull --ff-only || echo "Failed to update $name" >&2
    else
      echo "Cloning $name..."
      git clone "$url" "$name" || echo "Failed to clone $name" >&2
    fi
  done

  (( count < per_page )) && break
  ((page++))
done

echo "Done."
