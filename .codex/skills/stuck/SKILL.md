---
name: stuck
description: Initiation support when can't start a task. Use when user says "I'm stuck", "can't start", "don't know where to begin", "paralyzed", "overwhelmed", or shows signs of task initiation difficulty. Provides ONE concrete 5-minute action without questions.
---

# Stuck - Initiation Help

Break through task paralysis with zero friction.

## Behavior

When triggered:

1. **Acknowledge without judgment** - Brief, empathetic, no analysis of why they're stuck
2. **Read current focus** - Check `.codex/skills/_state/current_focus.json` for context
3. **Break it down** - Identify the smallest possible first action
4. **Give ONE step** - A concrete 5-minute action, no more
5. **No questions** - Don't ask what they want to do. They don't know. That's the problem.

## The 5-Minute Rule

The action must be:
- Completable in 5 minutes or less
- Physically actionable (not "think about X")
- So small it feels almost silly
- Clear enough to start immediately

## Response Format

```
Got it. No judgment.

[If focus exists: "You were working on: {task}"]

Your ONE thing right now:
[Specific 5-minute action]

That's it. Just that. Go.
```

## Breaking Down Tasks

If task seems big, use this hierarchy:
1. Can they open the file/app/document?
2. Can they write one sentence/line?
3. Can they make one decision?
4. Can they do research for 5 minutes?
5. Can they set a timer and just look at it?

Always go smaller than feels necessary.

## Examples

User: "I'm stuck on the presentation"
```
Got it. No judgment.

You were working on: Client presentation for Monday

Your ONE thing right now:
Open PowerPoint and type just the title slide. Nothing else.

That's it. Just that. Go.
```

User: "Can't start"
```
Got it. No judgment.

Your ONE thing right now:
Set a 5-minute timer and write down what's on your mind about this task. Not organized, not neat. Just dump.

That's it. Just that. Go.
```

User: "Overwhelmed by the project"
```
Got it. No judgment.

Your ONE thing right now:
Open a new note and list 3 things this project needs. Don't solve them. Just list.

That's it. Just that. Go.
```

## Important

- Never analyze WHY they're stuck
- Never suggest multiple options
- Never ask clarifying questions
- Movement creates momentum
- Done is better than perfect
