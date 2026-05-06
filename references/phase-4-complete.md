# Phase 4 — Parent Ticket Completion

## Pre-check

⚠️ Auto-detect whether anything needs pushing:

```bash
git rev-list @{u}..HEAD --count 2>/dev/null && echo "ok" || echo "no-upstream"
```

Result interpretation:

- **Number > 0**: Unpushed commits exist → ask the push question below.
- **0**: All commits are already pushed → skip the question.
- **no-upstream**: No upstream tracking branch → ask the push question below.

Only when push is needed:
> "Push to origin/[current branch]? (y/n)"

- **Approve (y)**: `git push -u origin [current branch]`
  - Execute mode: `{{BRANCH_PREFIX}}/_{{PROJECT_KEY}}-XXX/parent/{{PROJECT_KEY}}-XXX`
  - Direct mode (Story): the story parent branch
  - Direct mode (Task / Defect): `{{BRANCH_PREFIX}}/{{PROJECT_KEY}}-XXX`
- **Reject (n)**: notify "Continuing without push." and move on.

## Steps

1. Ask the user:
   > "Transition [{{PROJECT_KEY}}-XXX] to '{{DONE_STATUS}}' and post a summary comment? (y/n)"
2. On approval:
   - `mcp__atlassian__jira_transition_issue` → parent ticket to `{{DONE_STATUS}}` (use the saved `transitions.done` id).
   - `mcp__atlassian__jira_add_comment` with this body:

     ```
     ## Development Summary

     ### Goal
     [Restate the ticket's requirement in 1–2 sentences using non-technical language a PM/PO can understand]

     ### Implementation
     - **[Task 1 name]**: [What this Task solved and how, in 1–2 sentences. Minimize jargon.]
     - **[Task 2 name]**: [Same format]

     ### Verification
     [Whether tests were added, what was verified — e.g. "unit tests added", "all existing tests pass"]
     ```

     > Authoring rule: a non-developer teammate (PM/PO) should understand WHAT changed and WHY. Cross-reference the ticket's description / acceptance criteria with the actual changes made.

Workflow done.
