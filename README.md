# NeuroOS

> A personal operating system for ADHD founders, builders, and operators.
> Bypass the prefrontal cortex with shell scripts, launchd, and iMessage.

This is the **free kernel** — the 6 AM Morning Brief that runs your day before your brain comes online.

```
6:00 AM  →  launchd fires
         →  reads your calendar (today's events)
         →  reads ALL_DEADLINES.md (top 3 due in 72h)
         →  reads priorities.md (top 3 today)
         →  Claude composes a 7-line brief
         →  Messages.app sends iMessage to your phone
         →  archives to your journal

You wake up. You read 1 message. You know what to do.
No app to open. No tab to find. No decision to make.
```

---

## Why this exists

ADHD founders fail not from lack of ambition but from **decision fatigue at 6 AM**. The first hour of the day is when your prefrontal cortex is least online — and it's the hour every productivity app demands you log in, scroll, prioritize, choose.

NeuroOS inverts the contract. Your day is **already decided** by the time your eyes open. The system reads your inputs the night before and pushes one tactical message to your lock screen.

Built and battle-tested by [@jjawnee](https://x.com/jjawnee) — neuroscience student, founder, ADHD-wired.

---

## What you get (this repo, free)

- **`bin/morning-brief.sh`** — 200-line zsh kernel. Calendar.app + deadlines + priorities → 7-line iMessage at 6 AM.
- **`launchd/com.neuroos.morningbrief.plist`** — macOS launchd job that fires it daily.
- **`install.sh`** — one-command install. Edits paths, copies plist, loads launchd.
- **`examples/`** — template `priorities.md` and `ALL_DEADLINES.md` to get you started.

That's the whole free kernel. Runs forever. MIT licensed. No telemetry, no account, no cloud.

---

## What's in NeuroOS Pro ($29 one-time)

The free kernel proves the pattern works. **Pro is the full kit:**

| Pro module | Fires at | What it does |
|---|---|---|
| **Modular brief engine** | 6:00 AM | The pluggable adapter system that powers Johnny's actual prod brief — calendar, deadlines, financial, ventures, classes, priorities, carryover, inbox. Pluggable. Extensible. |
| **Morning check-in** | 7:00 AM | Habit-stack accountability — 11 questions, reply Y/N |
| **Midday checkpoint** | 12:30 PM | "This morning you said X — did it happen?" |
| **Evening close** | 9:30 PM | 3-question journal trigger before laptop shuts |
| **Bedtime stack** | 9:00 PM | Day-of-week-rotated wind-down protocol |
| **Friday week-in-review** | 5:00 PM Fri | Claude synthesizes journal + git → markdown + iMessage |
| **Sunday triage nudge** | 6:00 PM Sun | Counts inbox, only fires if work to do |
| **Week-ahead trigger** | 6:00 PM Sun | 5 prompts to plan the week before it eats you |
| **Danger-window nudge** | 7:00 PM Fri/Sat/Sun | Time-keyed sobriety / impulse-control protocol |
| **Cowork-stager** | 10:00 PM | Pre-stages tomorrow's brief data so 6 AM is instant |
| **PBP doctrine** | (Day 3 drop) | The Prefrontal Bypass Protocol — the 4-layer methodology behind the system |

→ **[Buy NeuroOS Pro on Gumroad](https://jjawnee.gumroad.com/l/ooxzqp)** — $29 one-time, lifetime updates.

---

## Quick start

```bash
git clone https://github.com/jjawnee/neuroos
cd neuroos
./install.sh
```

The installer asks for your iMessage phone number, templates the launchd plist with your `$HOME`, drops the script into `~/.config/neuroos/`, and loads the 6 AM job.

**First run:** `touch /tmp/morningbrief-test.flag && ~/.config/neuroos/bin/morning-brief.sh`
You should get a `[TEST]` iMessage within 30 seconds.

See [INSTALL.md](INSTALL.md) for the full setup, including Calendar.app permissions, Messages.app permissions, and the Claude CLI dependency.

---

## What you'll need

- macOS 12+ (uses Calendar.app, Messages.app, launchd, osascript)
- [Claude CLI](https://docs.claude.com/claude-code) installed and authenticated
- iMessage active on this Mac (signed in to your Apple ID)
- A `priorities.md` file (template in `examples/`)
- A `ALL_DEADLINES.md` file (template in `examples/`)

---

## The philosophy

> "Your prefrontal cortex is the bottleneck. Engineer around it, not through it."

- **Decision-cost minimization.** The brief makes decisions for you so you don't have to make them tired.
- **No app.** Your phone's lock screen is the UI. Notifications are the API.
- **Local-first.** Files on disk. No SaaS. No login. No sync conflict.
- **Composable.** Every script is a 100-line zsh file. Read it. Edit it. Fork it.

---

## License

MIT. See [LICENSE](LICENSE).

The Pro kit ships under a separate license (single-user, redistribution prohibited) — see Gumroad listing for terms.

---

**Questions?** [@jjawnee on X](https://x.com/jjawnee).
**Bug?** Open an issue on this repo.
**Want the full kit?** [Gumroad](https://jjawnee.gumroad.com/l/ooxzqp) → $29.
