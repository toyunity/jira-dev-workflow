# Phase 3-direct — Direct Work Mode

Entered when the user chose direct work for a Story, OR when the ticket type is Task / Sub-task / Defect.

## Branch setup (once per Task)

| Type | Branch |
|------|--------|
| Story (direct mode) | Reuse the parent branch |
| Task / Defect | `bash ~/.claude/skills/jira-dev-workflow/scripts/create-branch.sh [ticket]` |
| Sub-task | `bash ~/.claude/skills/jira-dev-workflow/scripts/create-branch.sh [parent-ticket] [ticket]` |

> Paths assume the standard install location. If the skill was installed elsewhere, substitute that path. See README §4.

## Code work

Same scope rule + subagent fallback as Phase 3-2:

**Scope: large** (≥3 files modified or created, OR adds a new Controller/Service/Repository class):
- **Detect `code-task-agent`** the same way as `phase-3-execute.md §3-2` (check the available `subagent_type` list, or attempt-and-classify).
- If available → spawn via the `Agent` tool with `subagent_type: "code-task-agent"`.
  - Input: ticket, Task description, target files / classes, pattern doc paths, current branch, project root.
  - Output: `{ summary, changed_files, commit_message_suggestion, test_result }`.
  - On completion → update `.claude/jira-workflow-state.json` and proceed to commit (3-3 procedure).
- If NOT available → read project pattern docs and implement inline (see phase-3-execute.md §3-2 fallback). Proceed to commit afterward.

**Scope: small** (otherwise) → read project pattern docs first, then implement inline. Proceed to commit afterward.

## Commit approval

Same as Phase 3-3.

After the commit, run the Jira transition based on ticket type:

| Entry path | Transition target | How |
|------------|-------------------|-----|
| Story (direct) | — | No transition — Phase 4 transitions the parent in bulk. |
| Task / Defect | The same ticket | `mcp__atlassian__jira_get_transitions` → extract `{{DONE_STATUS}}` id → `mcp__atlassian__jira_transition_issue` |
| Sub-task | The sub-task ticket | `mcp__atlassian__jira_get_transitions` → extract `{{DONE_STATUS}}` id → `mcp__atlassian__jira_transition_issue` |

> For Task / Defect / Sub-task paths, fetch the `transition_id` dynamically via `get_transitions` each time (same principle as elsewhere — workflows can differ per issue type).

After all Tasks complete, the message depends on ticket type:
- **Task / Defect**: "Open a merge request from `{{BRANCH_PREFIX}}/{{PROJECT_KEY}}-XXX` into `{{BASE_BRANCH}}` manually."
- **Sub-task**: "Open a merge request from `{{BRANCH_PREFIX}}/_{{PROJECT_KEY}}-XXX/{{PROJECT_KEY}}-YYY` into the parent branch manually."
- **Story (direct)**: Phase 4 will push and the user opens the MR.

Then read `references/phase-3-review.md` and run code review.
