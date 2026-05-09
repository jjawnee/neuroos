#!/bin/zsh
# install.sh — NeuroOS free-tier installer.
# Idempotent: safe to re-run.

set -eu
set -o pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
JO_ROOT="${JO_ROOT:-$HOME/.config/neuroos}"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.neuroos.morningbrief.plist"

printf '\n🧠 NeuroOS Morning Brief — installer\n\n'

# Prompt for iMessage recipient
if [ -z "${RECIPIENT:-}" ]; then
  printf 'iMessage handle (phone like +14155550100 or Apple ID email): '
  read -r RECIPIENT
fi
if [ -z "$RECIPIENT" ]; then
  printf 'ERROR: RECIPIENT cannot be empty.\n' >&2
  exit 1
fi

# Preflight
command -v claude >/dev/null 2>&1 || {
  printf 'ERROR: claude CLI not found on PATH. Install: npm i -g @anthropic-ai/claude-code\n' >&2
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  printf 'ERROR: jq not found. Install: brew install jq\n' >&2
  exit 1
}

# Build directory tree
mkdir -p "$JO_ROOT/bin" \
         "$JO_ROOT/daily" \
         "$JO_ROOT/school/extracted" \
         "$JO_ROOT/journal" \
         "$JO_ROOT/logs"

# Copy script
cp "$REPO/bin/morning-brief.sh" "$JO_ROOT/bin/morning-brief.sh"
chmod +x "$JO_ROOT/bin/morning-brief.sh"

# Seed example files if absent
if [ ! -f "$JO_ROOT/daily/priorities.md" ]; then
  cp "$REPO/examples/priorities.md" "$JO_ROOT/daily/priorities.md"
fi
if [ ! -f "$JO_ROOT/school/extracted/ALL_DEADLINES.md" ]; then
  cp "$REPO/examples/ALL_DEADLINES.md" "$JO_ROOT/school/extracted/ALL_DEADLINES.md"
fi

# Template + install plist
mkdir -p "$LAUNCHD_DIR"
TARGET_PLIST="$LAUNCHD_DIR/$PLIST_NAME"
sed -e "s|__HOME__|$HOME|g" \
    -e "s|__JO_ROOT__|$JO_ROOT|g" \
    -e "s|__RECIPIENT__|$RECIPIENT|g" \
    "$REPO/launchd/$PLIST_NAME" > "$TARGET_PLIST"

# Reload launchd
launchctl unload "$TARGET_PLIST" 2>/dev/null || true
launchctl load   "$TARGET_PLIST"

printf '\n✅ Installed.\n'
printf '   Script:    %s/bin/morning-brief.sh\n' "$JO_ROOT"
printf '   Plist:     %s\n' "$TARGET_PLIST"
printf '   Edit:      %s/daily/priorities.md\n' "$JO_ROOT"
printf '   Logs:      %s/logs/morning-brief.log\n\n' "$JO_ROOT"
printf '   Test now:  touch /tmp/morningbrief-test.flag && %s/bin/morning-brief.sh\n\n' "$JO_ROOT"
