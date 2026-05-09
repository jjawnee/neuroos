#!/bin/zsh
# morning-brief.sh — composes and sends a 7-line Morning Brief via iMessage.
# Invoked by launchd (com.neuroos.morningbrief) at 06:00 local time.
# Safe to invoke manually for priming / debugging.
#
# All paths and the recipient are env-var overridable. Defaults assume
# the install layout under $HOME/.config/neuroos/.

set -eu
set -o pipefail

# ===== PATH (launchd runs with minimal env; hydrate for nvm/homebrew binaries) =====
export PATH="${PATH}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# Try to add nvm node bin if present (for users who installed claude CLI via nvm).
if [ -d "$HOME/.nvm/versions/node" ]; then
  NVM_LATEST="$(ls -1 "$HOME/.nvm/versions/node" 2>/dev/null | sort -V | tail -1 || true)"
  [ -n "${NVM_LATEST:-}" ] && export PATH="$HOME/.nvm/versions/node/$NVM_LATEST/bin:$PATH"
fi

# ===== Clean inherited Claude Code env so claude -p doesn't refuse as nested =====
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_SSE_PORT CLAUDE_CODE_OAUTH_TOKEN 2>/dev/null || true

# ===== Constants (env-overridable) =====
JO_ROOT="${JO_ROOT:-$HOME/.config/neuroos}"
RECIPIENT="${RECIPIENT:-}"
DEADLINES="${DEADLINES_FILE:-$JO_ROOT/school/extracted/ALL_DEADLINES.md}"
PRIORITIES="${PRIORITIES_FILE:-$JO_ROOT/daily/priorities.md}"
INBOX="${INBOX_DIR:-$JO_ROOT/inbox}"
JOURNAL_ROOT="${JOURNAL_ROOT:-$JO_ROOT/journal}"
LOG_DIR="${LOG_DIR:-$JO_ROOT/logs}"
LOG="$LOG_DIR/morning-brief.log"
TEST_FLAG="/tmp/morningbrief-test.flag"
CLAUDE="$(command -v claude || true)"
BODY_FILE="$(mktemp -t morningbrief.XXXXXX)"

mkdir -p "$LOG_DIR"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*" >> "$LOG"; }
cleanup() { rm -f "$BODY_FILE"; }
trap cleanup EXIT

log "=========================================="
log "morning-brief START (pid=$$)"

# ===== Test-mode detection =====
TEST_PREFIX=""
if [ -f "$TEST_FLAG" ]; then
  TEST_PREFIX="[TEST 6AM BRIEF] "
  rm -f "$TEST_FLAG"
  log "Test flag consumed; prefix='${TEST_PREFIX}'"
fi

# ===== Preflight =====
if [ -z "$RECIPIENT" ]; then
  log "FATAL: RECIPIENT not set. Export RECIPIENT=+15555550100 or set in plist."
  exit 1
fi
if [ -z "$CLAUDE" ] || [ ! -x "$CLAUDE" ]; then
  log "FATAL: claude CLI not found on PATH. Install @anthropic-ai/claude-code."
  exit 1
fi
if [ ! -f "$DEADLINES" ]; then
  log "WARN: deadlines file missing at $DEADLINES — continuing with placeholder"
  DEADLINES_CONTENT="(no deadlines file)"
else
  DEADLINES_CONTENT="$(cat "$DEADLINES")"
fi
if [ ! -f "$PRIORITIES" ]; then
  log "WARN: priorities file missing at $PRIORITIES — continuing with placeholder"
  PRIORITIES_CONTENT="(no priorities file)"
else
  PRIORITIES_CONTENT="$(cat "$PRIORITIES")"
fi

# ===== Today's date =====
TODAY_PRETTY="$(date '+%A, %b %-d, %Y')"
log "Today: $TODAY_PRETTY"

# ===== Calendar.app events for today =====
CALENDAR_EVENTS="$(osascript <<'SCPT' 2>>"$LOG"
tell application "Calendar"
  set startOfDay to current date
  set hours of startOfDay to 0
  set minutes of startOfDay to 0
  set seconds of startOfDay to 0
  set endOfDay to startOfDay + 1 * days
  set out to ""
  repeat with c in calendars
    try
      set evs to (every event of c whose start date is greater than or equal to startOfDay and start date is less than endOfDay)
      if (count of evs) > 0 then
        repeat with e in evs
          set tstr to "(allday)"
          try
            set tstr to time string of (start date of e)
          end try
          set sstr to "(no title)"
          try
            set sstr to summary of e
          end try
          set out to out & tstr & " | " & sstr & " | " & (name of c) & linefeed
        end repeat
      end if
    end try
  end repeat
  return out
end tell
SCPT
)" || true
[ -z "${CALENDAR_EVENTS:-}" ] && CALENDAR_EVENTS="(no events today)"

# ===== Inbox count =====
INBOX_COUNT=0
if [ -d "$INBOX" ]; then
  INBOX_COUNT=$(find "$INBOX" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
fi
log "Inbox unprocessed: $INBOX_COUNT items"

# ===== Build prompt =====
PROMPT="You are composing a Morning Brief for ${TODAY_PRETTY}.

OUTPUT CONSTRAINTS (STRICT):
- Output EXACTLY 7 lines separated by newlines.
- No markdown, no code fences, no commentary before or after.
- Line starts may use ONLY these emojis: 📅 ⏰ 🎯 ↩️ 📧 (nothing else).
- TEST_PREFIX below may be empty. If non-empty, prepend it verbatim (with its trailing space) to the start of Line 1 BEFORE any other text.

TEST_PREFIX: \"${TEST_PREFIX}\"

LINE FORMAT:
Line 1: {TEST_PREFIX}Morning Brief · {Day Mon D}
Line 2: 📅 {events joined by \" · \" in chronological order}
        If no events today: \"📅 Open day\"
Line 3: ⏰ {Deadline 1 title (weight%) — Xd}
Line 4: ⏰ {Deadline 2 ...}
Line 5: ⏰ {Deadline 3 ...}
Line 6: 🎯 {Top 3 priorities, comma-separated}
        If none filled: \"🎯 Nothing set\"
Line 7: ↩️ {Yesterday's unfinished item, short}
        If empty: \"↩️ Clean slate\"

DEADLINE SELECTION RULES:
- Prefer items due within 72 hours of today.
- If fewer than 3 fall in that window, extend forward chronologically until you have 3.
- Sort chronologically (earliest first), ties broken by weight descending.
- For each item, extract: title (terse, 8-10 words max), weight percentage (parse \"15%\" or \"35%\"; if none, omit the \"(w%)\"), and days-until (0 → \"today\", 1 → \"tmrw\", otherwise \"Nd\").
- Treat past-dated items as resolved; do not include them.

CALENDAR TIME FORMAT: 12-hour compact (\"9a\", \"10:30a\", \"2p\", \"4:15p\"). All-day events: just the title.

=== TODAY_EVENTS (raw osascript output; lines formatted as TIME | TITLE | CALENDAR) ===
${CALENDAR_EVENTS}
=== END TODAY_EVENTS ===

=== ALL_DEADLINES.md ===
${DEADLINES_CONTENT}
=== END ALL_DEADLINES.md ===

=== priorities.md ===
${PRIORITIES_CONTENT}
=== END priorities.md ===

Output the 7 lines now. No preamble, no trailing blank lines."

log "Prompt built ($(printf '%s' "$PROMPT" | wc -c | tr -d ' ') chars)"

# ===== Invoke Claude =====
log "Invoking claude -p"
set +e
BRIEF="$("$CLAUDE" -p --tools "" --disallowed-tools "mcp__*" --model claude-sonnet-4-6 --output-format text "$PROMPT" 2>>"$LOG")"
BRIEF_EXIT=$?
set -e

if [ $BRIEF_EXIT -ne 0 ]; then
  log "FATAL: claude exit=$BRIEF_EXIT"
  exit 1
fi

# Trim trailing blank lines, normalize
BRIEF="$(printf '%s' "$BRIEF" | awk 'BEGIN{blank=0} /^$/{blank++; next} {while(blank-- > 0) print ""; blank=0; print}')"
LINE_COUNT=$(printf '%s\n' "$BRIEF" | awk 'END{print NR}')
log "Claude output: $LINE_COUNT lines, $(printf '%s' "$BRIEF" | wc -c | tr -d ' ') chars"

if [ "$LINE_COUNT" -lt 3 ] || [ "$LINE_COUNT" -gt 15 ]; then
  log "WARN: unexpected line count ($LINE_COUNT); sending anyway"
fi

printf '%s\n' "$BRIEF" > "$BODY_FILE"

# ===== Send iMessage =====
log "Sending iMessage to $RECIPIENT"
set +e
osascript >>"$LOG" 2>&1 <<SCPT
set bodyFile to POSIX file "$BODY_FILE"
set msgBody to read bodyFile as «class utf8»
tell application "Messages"
  set targetService to 1st service whose service type = iMessage
  set targetBuddy to buddy "$RECIPIENT" of targetService
  send msgBody to targetBuddy
end tell
SCPT
SEND_EXIT=$?
set -e

if [ $SEND_EXIT -eq 0 ]; then
  log "iMessage send: OK"
else
  log "iMessage send FAILED (exit=$SEND_EXIT)"
  exit $SEND_EXIT
fi

# ===== Archive to today's journal =====
JOURNAL_DIR="$JOURNAL_ROOT/$(date +%Y/%m)"
JOURNAL_FILE="$JOURNAL_DIR/$(date +%Y-%m-%d).md"
mkdir -p "$JOURNAL_DIR"
{
  echo ""
  echo "## Morning brief ($(date +%H:%M))"
  echo ""
  echo "📥 Inbox: ${INBOX_COUNT} unprocessed"
  echo ""
  cat "$BODY_FILE"
  echo ""
} >> "$JOURNAL_FILE"
log "Archived brief to $JOURNAL_FILE"

log "morning-brief END (pid=$$)"
log ""
