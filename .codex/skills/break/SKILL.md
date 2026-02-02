---
name: break
description: Log a break and set return intention. Use when user says "taking a break", "need a break", "stepping away", "back in X minutes", or shows signs of fatigue. Logs break, suggests duration, and sets clear return intention.
---

# Break - Rest and Return

Log breaks and set intentions to support healthy work rhythm.

## State Files

- Session log: `.codex/skills/_state/session_log.jsonl`
- Current focus: `.codex/skills/_state/current_focus.json`

## Behavior

When triggered:

1. **Log the break** - Append to session_log.jsonl
2. **Suggest duration** - Based on time worked
3. **Set return intention** - What we'll do when back
4. **Remind about quality** - Walk, not phone

## Session Log Format

Append to `.codex/skills/_state/session_log.jsonl`:
```json
{"type": "break_start", "timestamp": "ISO", "focus_task": "what we were doing", "time_worked_minutes": 45, "suggested_break_minutes": 10}
```

When user returns, log:
```json
{"type": "break_end", "timestamp": "ISO", "actual_break_minutes": 12}
```

## Break Duration Guidelines

| Time Worked | Suggested Break |
|-------------|-----------------|
| < 25 min    | 5 min           |
| 25-50 min   | 10 min          |
| 50-90 min   | 15-20 min       |
| > 90 min    | 20-30 min       |

## Response Format

```
Break logged.

Time worked: [X] minutes on [task]
Suggested break: [Y] minutes

When you return: [specific next action]

Reminder: Walk, stretch, look at something far away. Not your phone.
```

## Setting Return Intention

Read current focus and identify:
- What step we were on
- What the immediate next action is
- Frame it as a clear, small task

Good: "When you return: Open the spreadsheet and fill in column B"
Bad: "When you return: Continue working on the report"

## Examples

User: "Taking a break"
```
Break logged.

Time worked: 47 minutes on Client presentation
Suggested break: 10 minutes

When you return: Add the 3 competitor logos to slide 6

Reminder: Walk, stretch, look at something far away. Not your phone.
```

User: "Need to step away"
```
Break logged.

Time worked: 23 minutes on Code review
Suggested break: 5 minutes

When you return: Finish reviewing the auth module changes

Reminder: Walk, stretch, look at something far away. Not your phone.
```

## When User Returns

When user says "back" or "I'm back":

1. Log break_end in session_log.jsonl
2. Remind them of the return intention
3. Offer the first small step

```
Welcome back. Break was [X] minutes.

Return intention: Add the 3 competitor logos to slide 6

Ready to start? Open the presentation file.
```
