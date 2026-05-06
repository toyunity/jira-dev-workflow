# Phase 3 — Task Loop Execution

Iterate over the Task list from the Phase 2 completion table.
At the start of each Task, print the progress: `[Current Task N / Total M]`.

Before starting, ask the user:
> "Running [M] Tasks total.
   (y) Confirm before each Task
   (n) Auto-sequential (commit approval is ALWAYS still requested)"

## 3-1. Task start

### 3-1-confirm. Per-Task confirmation (only in confirm mode)

Ask only when "y" was chosen above:
> "[Task N/M] [{{PROJECT_KEY}}-ZZZ] [Name] — start? (y/n)"

- **Reject (n)**:
  > "Skip this Task. Move on to the next one? (y/n)"
  - Approve (y): set `status` to `skipped` for this task in `.claude/jira-workflow-state.json`, then move to the next Task.
  - Reject (n): save state per `references/workflow-state.md` and abort.
    (The current task stays `not_started` → on resume, re-enter at 3-1-confirm.)

### 3-1-setup. Task setup (always runs)

Runs for both confirm-mode approval and auto mode:

1. `mcp__atlassian__jira_get_transitions` against the **child ticket** ([{{PROJECT_KEY}}-ZZZ]):
   - Extract `{{IN_PROGRESS_STATUS}}` transition_id → `task.transitions.in_progress`.
   - Extract `{{DONE_STATUS}}` transition_id → `task.transitions.done`.
   - Save both onto the corresponding task entry in `.claude/jira-workflow-state.json`.
   - If the `{{IN_PROGRESS_STATUS}}` transition is missing, print available transitions and confirm with the user.
2. `mcp__atlassian__jira_transition_issue` with the extracted `task.transitions.in_progress` id.
3. Run `bash ~/.claude/skills/jira-dev-workflow/scripts/create-branch.sh [parent-ticket] [sub-ticket]` (this assumes the standard install location — see README §4 if you installed elsewhere; in that case substitute the actual path).
4. Update the task `status` in `.claude/jira-workflow-state.json` to `in_progress`.

## 3-2. Code work

Determine Task scope:

**Scope: large** (≥3 files modified or created, OR adds a new Controller/Service/Repository class):

**Detect `code-task-agent` availability** (do this once per workflow, cache the result):

- If the host exposes the available `subagent_type` list, look up `code-task-agent` directly.
- Otherwise, just attempt to spawn (next bullet) — treat an "unknown subagent_type" / "agent not found" error from the `Agent` tool as the missing signal and fall through to inline implementation.

- **If `code-task-agent` is available** → spawn it via the `Agent` tool with `subagent_type: "code-task-agent"`.

  Pass the following as the Agent prompt:

  ```
  Context: [{{PROJECT_KEY}}-ZZZ]
  Task: [Task name]
  Description: [Full Task description from Phase 2 plan]
  Targets: [Files / classes identified in Phase 2]
  Branch: [Current branch name]
  Pattern docs:
    - [Project rules/style-guide path appropriate to this Task]
    - [Patterns doc path appropriate to this Task]
  Project root: [pwd]
  ```

  After the subagent returns:
  - Find the last ` ```json ... ``` ` block in its output and parse `{ summary, changed_files, commit_message_suggestion, test_result }`.
  - If no JSON block can be parsed:
    > "Could not parse JSON from the agent output. Please verify the work manually."
    Run `git status` to confirm changes, then proceed to commit (3-3) directly.
  - Update `.claude/jira-workflow-state.json`: `{ "ticket": "{{PROJECT_KEY}}-ZZZ", "summary": "...", "changed_files": [...] }`.
  - If a `notes` field is present, surface it to the user.

- **If `code-task-agent` is NOT available** → fall back to inline implementation. Notify the user once per workflow:
  > "Using inline mode for large-scope Tasks (`code-task-agent` not installed). To enable the dedicated subagent, see README §4 Step 3 — the agent definition ships with this skill at `agents/code-task-agent.md`."

  Then:
  - Read the project's pattern docs (`CLAUDE.md`, style guides) referenced in the Phase 2 plan.
  - Implement the changes directly in the main session, file by file.
  - When done, gather the equivalent metadata yourself: `summary` (1–2 sentences), `changed_files` (from `git status`), and a draft `commit_message_suggestion` for step 3-3.
  - Save the same shape into `.claude/jira-workflow-state.json`.
  - Then proceed to step 3-3 with the drafted commit message.

**Scope: small** (otherwise) → read project pattern docs first, then implement inline. After implementation, proceed to step 3-3.

## 3-3. Commit approval

Before committing, run `git status` to confirm changed files:

- **No changes**: skip the commit, only run the Jira state transition, then go to 3-4.

When there are changes, propose a commit message:

```
<gitmoji> <type>: <one-line subject>

<body — optional>
```

Gitmoji map: feat→✨ fix→🐛 refactor→♻️ test→✅ docs→📝 style→💄 chore→🔧 build→👷

> "Commit with this message?\n[message]\n(y/n)"

- **Approve (y)**:
  1. Stage only the relevant files explicitly (avoid `git add -A`).
  2. `git commit -m "[message]"`.
  3. Only if task `status` is not `committed` or `completed`:
     - Read `tasks[].transitions.done` for this task from `.claude/jira-workflow-state.json`.
     - `mcp__atlassian__jira_transition_issue` with that id (transition the child ticket to `{{DONE_STATUS}}`).
  4. Update task `status` to `committed` in `.claude/jira-workflow-state.json`.
- **Reject (n)**: revise the message and re-propose.

## 3-4. Merge approval

After the commit, ask the user:
> "Merge [child branch] into [parent branch]? (y/n)"

- **Approve (y)**:
  1. `git checkout [parent branch]`.
  2. `git merge --no-ff [child branch] -m "Merge [{{PROJECT_KEY}}-ZZZ]: [Task name]"`.
  3. Print a merge-complete message.
  4. Update task `status` to `completed`.
- **Reject (n)**: notify "Merge later manually" and move to the next Task.
  (`status` stays `committed` → on resume, re-enter at 3-4.)

If a merge conflict occurs → report to the user and abort.

---

After the last Task completes → read `references/phase-3-review.md` and run code review.
