# NeuroOS — Install Guide

5-minute setup. Your first brief lands tomorrow at 6 AM.

## Prerequisites

| Thing | Why | How |
|---|---|---|
| macOS 12+ | launchd, Messages.app, Calendar.app | You already have it. |
| Apple ID signed into Messages.app | iMessage delivery | `open -a Messages` → sign in if needed. |
| Calendar.app subscriptions | Reads today's events | Add Google/iCloud accounts via System Settings → Internet Accounts. |
| [Claude CLI](https://docs.claude.com/claude-code) | Composes the brief | `npm i -g @anthropic-ai/claude-code` then `claude login`. |
| `jq` | JSON parsing | `brew install jq` |

## One-command install

```bash
git clone https://github.com/jjawnee/neuroos
cd neuroos
./install.sh
```

The installer:
1. Prompts for your iMessage handle (phone number or Apple ID email).
2. Copies `bin/morning-brief.sh` to `~/.config/neuroos/bin/`.
3. Creates `~/.config/neuroos/{daily,school/extracted,journal,logs}/`.
4. Templates the launchd plist with your `$HOME` and recipient.
5. Copies the plist to `~/Library/LaunchAgents/`.
6. Runs `launchctl load` to schedule the 6 AM job.

## Configure your inputs

Edit two files (the installer copies starter templates):

**`~/.config/neuroos/daily/priorities.md`** — your top 3 for today:
```markdown
# Today's Top 3
- [ ] Ship the API endpoint
- [ ] 1:1 with advisor at 2 PM
- [ ] Finish biochem problem set
```

**`~/.config/neuroos/school/extracted/ALL_DEADLINES.md`** — upcoming deadlines:
```markdown
## EXAMPLE COURSE 101
- Mon 2026-05-12 23:59  Problem set 4 (15%)
- Wed 2026-05-14 23:59  Lab report (25%)

## EXAMPLE COURSE 102
- Tue 2026-05-13 17:00  Homework 5 (10%)
```

Format: `- <DDD> <YYYY-MM-DD> <HH:MM>  <title> (<weight>%)`. Weight is optional.

## Test it

```bash
touch /tmp/morningbrief-test.flag && ~/.config/neuroos/bin/morning-brief.sh
```

You should get a `[TEST 6AM BRIEF]` iMessage within 30 seconds. If not:

```bash
tail -50 ~/.config/neuroos/logs/morning-brief.log
```

Common causes:
- **Messages.app not authorized** → System Settings → Privacy & Security → Automation → grant Terminal/iTerm access to Messages.
- **Calendar.app empty** → Same flow, grant Calendar permission.
- **`claude` not on PATH** → Re-run `claude login` and verify with `which claude`.

## Permissions

macOS will prompt you the first time launchd runs the script:
1. **Calendar access** — accept (otherwise events line is empty).
2. **Automation → Messages** — accept (otherwise iMessage send fails).

You can pre-grant in System Settings → Privacy & Security → Automation.

## Customize

All paths are env-var overridable. Edit `~/Library/LaunchAgents/com.neuroos.morningbrief.plist` to inject:

```xml
<key>EnvironmentVariables</key>
<dict>
  <key>RECIPIENT</key>
  <string>+15555550100</string>
  <key>JO_ROOT</key>
  <string>/Users/you/custom/path</string>
</dict>
```

Reload after edits:
```bash
launchctl unload ~/Library/LaunchAgents/com.neuroos.morningbrief.plist
launchctl load   ~/Library/LaunchAgents/com.neuroos.morningbrief.plist
```

## Want more?

The free kernel runs forever. If you want time-keyed nudges (midday, evening, bedtime, weekly review), the modular brief engine, and the PBP doctrine — that's [NeuroOS Pro on Gumroad](https://jjawnee.gumroad.com/l/ooxzqp).

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.neuroos.morningbrief.plist
rm ~/Library/LaunchAgents/com.neuroos.morningbrief.plist
rm -rf ~/.config/neuroos
```
