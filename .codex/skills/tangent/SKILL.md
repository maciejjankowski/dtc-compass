---
name: tangent
description: Capture a distracting thought and return to focus. Use when user mentions something unrelated to current task, says "quick thought", "just remembered", "oh also", or needs to capture an idea without losing focus. Saves tangent and redirects.
---

# Tangent - Capture and Return

Capture distracting thoughts so they don't derail focus.

## State Files

- Captures: `.codex/skills/_state/captures.md`
- Current focus: `.codex/skills/_state/current_focus.json`

## Behavior

When triggered:

1. **Capture the tangent** - Append to `.codex/skills/_state/captures.md` with timestamp
2. **Acknowledge briefly** - Confirm it's saved
3. **Redirect immediately** - Return attention to current focus
4. **No engagement** - Don't discuss the tangent, don't explore it

## Capture Format

Append to `.codex/skills/_state/captures.md`:
```markdown
## [ISO timestamp]
[The tangent thought/idea/task]

---
```

## Response Format

```
Captured for later.

Back to focus: [current task from current_focus.json]
[Next step or reminder of where we were]
```

## Examples

User: "Oh wait, I should also email John about the budget"
```
Captured for later.

Back to focus: Write Q1 roadmap document
You were working on the timeline section.
```

User: "Quick thought - we should add dark mode to the app"
```
Captured for later.

Back to focus: Fix login bug
Next step: Check the authentication error logs.
```

User: "I just remembered I need to..."
```
Captured for later.

Back to focus: Client presentation
You were on slide 4, the competitive analysis.
```

## If No Focus Set

If `.codex/skills/_state/current_focus.json` is empty or missing:

```
Captured for later.

No active focus set. Want to set one now, or review your captures?
```

## Important

- Be fast. The goal is minimal interruption.
- Don't ask about the tangent
- Don't judge the tangent
- Don't help with the tangent
- Just capture and redirect
- The tangent will be there later during review
