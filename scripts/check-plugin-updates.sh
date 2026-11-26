#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

LOCK_FILE="plugins.lock.json"
SUMMARY_FILE="plugin_updates_summary.md"
TMUX_CONF="tmux.conf"

if [ ! -f "$TMUX_CONF" ]; then
    echo "Error: $TMUX_CONF not found." >&2
    exit 1
fi

echo "Scanning $TMUX_CONF for plugins..."
plugins=$(grep -E "^[[:space:]]*set(-option)?[[:space:]]+-g[[:space:]]+@plugin[[:space:]]+" "$TMUX_CONF" | sed -E "s/.*@plugin[[:space:]]+['\"]?([^'\"]+)['\"]?.*/\1/")

# Load existing lockfile or initialize empty JSON
if [ -f "$LOCK_FILE" ]; then
    lock_data=$(cat "$LOCK_FILE")
else
    lock_data="{}"
fi

updated=0
echo "## Tmux Plugin Updates Summary" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "| Plugin | Previous SHA | Latest SHA | Release/Tag |" >> "$SUMMARY_FILE"
echo "| :--- | :--- | :--- | :--- |" >> "$SUMMARY_FILE"

new_lock_data="$lock_data"

while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    repo="${plugin%%#*}"
    echo "Checking $plugin..."
    
    # Fetch latest commit info via GitHub API
    api_url="https://api.github.com/repos/${repo}/commits/HEAD"
    auth_header=()
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
    fi

    commit_res=$(curl -fsSL "${auth_header[@]}" "$api_url" 2>/dev/null || echo "{}")
    latest_sha=$(echo "$commit_res" | jq -r '.sha // empty' 2>/dev/null || true)
    
    if [ -z "$latest_sha" ]; then
        echo "Warning: Could not fetch commit info for $plugin" >&2
        continue
    fi

    short_sha="${latest_sha:0:7}"

    # Fetch latest release/tag if available
    tag_res=$(curl -fsSL "${auth_header[@]}" "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null || echo "{}")
    latest_tag=$(echo "$tag_res" | jq -r '.tag_name // "HEAD"' 2>/dev/null || echo "HEAD")

    # Read previous recorded SHA
    prev_sha=$(echo "$lock_data" | jq -r --arg p "$plugin" '.[$p].sha // empty' 2>/dev/null || true)

    if [ -z "$prev_sha" ]; then
        echo "Initial record for $plugin: $short_sha ($latest_tag)"
        new_lock_data=$(echo "$new_lock_data" | jq --arg p "$plugin" --arg sha "$latest_sha" --arg tag "$latest_tag" '.[$p] = {sha: $sha, tag: $tag}')
        echo "| [$plugin](https://github.com/$repo) | (initial) | [\`$short_sha\`](https://github.com/$repo/commit/$latest_sha) | $latest_tag |" >> "$SUMMARY_FILE"
        updated=1
    elif [ "$prev_sha" != "$latest_sha" ]; then
        prev_short="${prev_sha:0:7}"
        echo "Update found for $plugin: $prev_short -> $short_sha ($latest_tag)"
        new_lock_data=$(echo "$new_lock_data" | jq --arg p "$plugin" --arg sha "$latest_sha" --arg tag "$latest_tag" '.[$p] = {sha: $sha, tag: $tag}')
        echo "| [$plugin](https://github.com/$repo) | [\`$prev_short\`](https://github.com/$repo/commit/$prev_sha) | [\`$short_sha\`](https://github.com/$repo/commit/$latest_sha) | $latest_tag |" >> "$SUMMARY_FILE"
        updated=1
    else
        echo "$plugin is up to date ($short_sha)."
    fi
done <<< "$plugins"

# Prune plugins removed from tmux.conf
while IFS= read -r existing_plugin; do
    [[ -z "$existing_plugin" ]] && continue
    if ! printf '%s\n' "$plugins" | grep -Fxq "$existing_plugin"; then
        echo "Removing unused plugin from lockfile: $existing_plugin"
        new_lock_data=$(echo "$new_lock_data" | jq --arg p "$existing_plugin" 'del(.[$p])')
        echo "| $existing_plugin | (removed) | - | - |" >> "$SUMMARY_FILE"
        updated=1
    fi
done < <(echo "$lock_data" | jq -r 'keys[]')

echo "$new_lock_data" | jq '.' > "$LOCK_FILE"

if [ "$updated" -eq 1 ]; then
    echo "Updates were recorded in $LOCK_FILE."
    cat "$SUMMARY_FILE"
else
    echo "All plugins are already up to date."
    rm -f "$SUMMARY_FILE"
fi
