---
name: review
description: Daily or weekly review helper for reflection and planning. Use when user says "review", "what did I do", "weekly review", "daily review", "end of day", "end of week", or wants to process captures and plan ahead.
---

# Review - Reflect and Plan

Process work history, captures, and set intentions.

## State Files

- Session log: `.codex/skills/_state/session_log.jsonl`
- Captures: `.codex/skills/_state/captures.md`
- Energy log: `.codex/skills/_state/energy_log.json`
- Current focus: `.codex/skills/_state/current_focus.json`

## Review Types

### Daily Review (end of day, ~10 min)

1. **Read session_log.jsonl** for today's entries
2. **Summarize accomplishments** - What got done
3. **Read captures.md** - List unprocessed tangents
4. **Set tomorrow's first task** - Reduce morning friction
5. **Clear current focus** - Day is done

### Weekly Review (end of week, ~30 min)

1. **Read session_log.jsonl** for the week
2. **Summarize the week** - Patterns, wins, struggles
3. **Process all captures** - Decide: do, delegate, delete, defer
4. **Identify patterns** - Energy levels, focus times, blockers
5. **Set ONE priority for next week**

## Session Log Analysis

Parse `.codex/skills/_state/session_log.jsonl` to find:
- Total focus time
- Number of breaks taken
- Average session length
- Tasks worked on

## Captures Processing

Read `.codex/skills/_state/captures.md` and for each item:
- **Do**: Add to task list / current focus
- **Delegate**: Note who to send it to
- **Delete**: Not worth doing
- **Defer**: Move to a "someday" list

After processing, archive or clear the captures file.

## Pattern Recognition

Look for:
- **Peak hours**: When were the longest focus sessions?
- **Energy dips**: When did breaks cluster?
- **Blockers**: What caused stuck moments?
- **Wins**: What tasks flowed easily?

## Response Format - Daily

```
## Daily Review - [date]

### Done Today
- [task 1]
- [task 2]
- [task 3]

### Unprocessed Captures
[count] items to review:
- [capture 1]
- [capture 2]

### Tomorrow's First Task
[Specific, small action to start the day]

---
Good work. Rest now.
```

## Response Format - Weekly

```
## Weekly Review - [date range]

### This Week's Wins
- [accomplishment 1]
- [accomplishment 2]

### Time Invested
- Total focus time: [X] hours
- Average session: [Y] minutes
- Breaks taken: [Z]

### Patterns Noticed
- Peak focus: [time range]
- Energy dips: [time range]
- Common blockers: [patterns]

### Captures to Process
[count] items:
1. [capture] - [do/delegate/delete/defer]
2. [capture] - [do/delegate/delete/defer]

### Next Week's ONE Thing
[Single most important priority]

---
Solid week. Rest and reset.
```

## Important

- Celebrate small wins - ADHD brains need positive reinforcement
- Be specific about tomorrow/next week - reduce decision fatigue
- Don't overwhelm with too many insights
- End on a positive note
