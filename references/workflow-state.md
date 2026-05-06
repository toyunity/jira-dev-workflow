# Workflow Pause & Resume

## On pause (user requested change / abort)

Save the current progress to `.claude/jira-workflow-state.json`:

```json
{
  "parentTicket": "{{PROJECT_KEY}}-XXX",
  "parentBranch": "{{BRANCH_PREFIX}}/_{{PROJECT_KEY}}-XXX/parent/{{PROJECT_KEY}}-XXX",
  "currentPhase": 3,
  "phase3Mode": "execute",
  "currentTaskIndex": 1,
  "tasks": [
    {
      "ticket": "{{PROJECT_KEY}}-YYY",
      "name": "Task 1: ...",
      "status": "completed",
      "transitions": { "in_progress": "<id>", "done": "<id>" }
    },
    {
      "ticket": "{{PROJECT_KEY}}-ZZZ",
      "name": "Task 2: ...",
      "status": "committed",
      "transitions": { "in_progress": "<id>", "done": "<id>" }
    },
    {
      "ticket": "{{PROJECT_KEY}}-WWW",
      "name": "Task 3: ...",
      "status": "not_started"
    }
  ],
  "transitions": {
    "in_progress": "<id>",
    "done": "<id>"
  }
}
```

Status values:

- `not_started`: not yet started (3-1-setup hasn't run).
- `in_progress`: 3-1-setup done, pre-commit (code work in flight).
- `committed`: commit done, pre-merge (3-3 done, 3-4 not).
- `completed`: merge done.
- `skipped`: user skipped this Task.

> The `tasks[].transitions` field is filled at 3-1-setup after `get_transitions` is called.
> `not_started` tasks omit the `transitions` field.
> The top-level `transitions` field holds the parent ticket's ids — used in Phase 4 for the parent transition.

After saving, print to the user:

```
⏸ Workflow paused.
Current position: Phase [N] — Task [M/T] ([{{PROJECT_KEY}}-ZZZ])
Type "resume" or "continue" to pick up from here.
```

## On resume ("resume", "continue", etc.)

1. Read `.claude/jira-workflow-state.json`.
2. If missing: "No saved workflow state. Provide a ticket number to start fresh."
3. Print a summary:

   ```
   ▶ Workflow resumed: [{{PROJECT_KEY}}-XXX]
   Phase [N] — Task list:
   ✅ [{{PROJECT_KEY}}-YYY] Task 1 (completed)
   🔄 [{{PROJECT_KEY}}-ZZZ] Task 2 (committed, pre-merge) ← resuming here
   ⬜ [{{PROJECT_KEY}}-WWW] Task 3 (not started)
   ```

4. Pick the re-entry point based on status:
   - `not_started`: re-enter at 3-1-confirm (confirm mode) or 3-1-setup (auto mode).
   - `in_progress`: re-enter at 3-2 (code work).
     - Reuse `tasks[].transitions` from state.json (no need to re-call `get_transitions`).
     - However, if Jira reports the ticket is already in `{{IN_PROGRESS_STATUS}}`, skip the transition call.
   - `committed`: re-enter at 3-4 (merge approval).
     - Reuse `tasks[].transitions.done` from state.json.

## Cleanup after resume

Delete `.claude/jira-workflow-state.json` when Phase 4 completes (workflow ends).
