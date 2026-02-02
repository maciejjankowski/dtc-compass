---
name: focus
description: Set or check current focus task for ADHD executive function support. Use when user says "focus on", "working on", "my focus is", "what am I working on", or needs help staying on task. Manages focus state and redirects tangents.
---

# Focus - Set Current Task

Manage the current focus task to support sustained attention.

## State File

Read and write focus state to: `.codex/skills/_state/current_focus.json`

Schema:
```json
{
  "task": "string - what we're working on",
  "started_at": "ISO timestamp",
  "time_estimate_minutes": "number or null",
  "context": "string - any relevant context",
  "subtasks": ["list of smaller steps if broken down"]
}
```

## Setting Focus

When user sets a new focus:

1. Read current state from `.codex/skills/_state/current_focus.json`
2. If there was a previous focus, acknowledge it briefly ("Switching from X")
3. Write new focus with:
   - task: what they said
   - started_at: current ISO timestamp
   - time_estimate_minutes: if they mentioned time, otherwise null
   - context: any relevant details
4. Confirm with a brief, action-oriented message:
   - State the focus task clearly
   - If time estimate given, note it
   - Give the first concrete step if the task is vague

## Checking Focus

When user asks "what am I working on" or seems lost:

1. Read `.codex/skills/_state/current_focus.json`
2. If no focus set: suggest setting one
3. If focus exists:
   - State the task
   - Calculate time elapsed since started_at
   - Remind of any subtasks
   - Suggest next action

## Tangent Detection

When user brings up something unrelated to current focus:

1. Politely note this seems like a tangent
2. Suggest using the `tangent` skill to capture it for later
3. Redirect back to the current focus task

Do not lecture. Do not ask questions. State what we're doing and move forward.

## Example Responses

Setting focus:
```
Focus set: Write Q1 roadmap document

Time estimate: 45 minutes
Started: now

First step: Open the roadmap template and list the 3 main sections.
```

Checking focus:
```
Current focus: Write Q1 roadmap document
Time elapsed: 23 minutes (of estimated 45)

Next: Complete the timeline section.
```
