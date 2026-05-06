---
name: jira-dev-workflow
description: "Automate the full analyze → plan → implement → complete development workflow from a Jira story ticket, with step-by-step user approvals."
when_to_use: |
  Trigger: "ENG-100 start work", "begin development on this ticket", "let's tackle ENG-100" — when you want to drive a Jira story ticket through the full phased workflow.
  Skip: "fix this bug" (direct code change without a Jira ticket), "summarize this ticket" (read-only Q&A), already-in-flight single Task work.
disable-model-invocation: false
user-invocable: true
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash(git:*)
  - Bash(bash ~/.claude/skills/jira-dev-workflow/scripts/*:*)
  - Skill
  - AskUserQuestion
  - Agent
  - mcp__atlassian__jira_get_issue
  - mcp__atlassian__jira_get_issues_development_info
  - mcp__atlassian__jira_transition_issue
  - mcp__atlassian__jira_get_transitions
  - mcp__atlassian__jira_add_comment
  - mcp__atlassian__jira_create_issue
  - mcp__atlassian__jira_get_user_profile
---

# Jira Development Workflow

## Required MCP server

This skill **cannot function** without a Jira MCP server registered in the host (Claude Code). All Phases call tools named `mcp__atlassian__jira_*`. Required tools:

- `mcp__atlassian__jira_get_issue`
- `mcp__atlassian__jira_get_transitions`
- `mcp__atlassian__jira_transition_issue`
- `mcp__atlassian__jira_create_issue`
- `mcp__atlassian__jira_add_comment`
- `mcp__atlassian__jira_get_user_profile`
- `mcp__atlassian__jira_get_issues_development_info` (used by some Phases)

If these tools are unavailable when the skill is invoked, abort immediately with:
> "This skill requires an Atlassian Jira MCP server. Configure one (e.g. `sooperset/mcp-atlassian`) so tools named `mcp__atlassian__jira_*` are available, then re-run."

The pre-flight check is the very first action in Phase 0 (see `references/phase-0-setup.md`).

## First-run Setup

If `.claude/jira-workflow-config.md` does not exist in the current project root:
→ Read `references/phase-0-setup.md` and run the setup wizard **before** Phase 1.

After setup completes, proceed to Phase 1 with the loaded config values.

For all subsequent runs, read `.claude/jira-workflow-config.md` once at the start and treat the values as the substitutions for `{{PROJECT_KEY}}`, `{{IN_PROGRESS_STATUS}}`, `{{DONE_STATUS}}`, `{{BRANCH_PREFIX}}`, `{{BASE_BRANCH}}`, `{{JIRA_USER_EMAIL}}` used throughout this skill.

## 4-Phase Flow

Read each Phase's reference file **immediately before** starting that Phase. Don't pre-read.

| Phase | Core Action | Reference |
|-------|-------------|-----------|
| 0. Setup (first run only) | Interview → write `.claude/jira-workflow-config.md` | `references/phase-0-setup.md` |
| 1. Analyze | Fetch ticket → validate type → request status transition approval | `references/phase-1-analyze.md` |
| 2. Plan | Decompose into Tasks → request Jira sub-task creation approval | `references/phase-2-plan.md` |
| 3. Execute | Per Task: branch → code → commit → status transition (loop) | `references/phase-3-execute.md` |
| 4. Complete | Move parent ticket to `{{DONE_STATUS}}` + post summary comment | `references/phase-4-complete.md` |

## Optional Dependencies

Some Phases enhance behavior with external skills / agents. If absent, fall back gracefully.

| Phase | Dependency | When available | When missing |
|-------|------------|----------------|--------------|
| 3. Execute (large-scope Task) | `code-task-agent` (subagent) | Spawn the subagent for isolated implementation | Read pattern docs and implement inline in the main session |
| 3. Review | `superpowers:requesting-code-review` (skill) | Invoke for diff review | Skip the review step with a notice to the user |

### How to detect availability

Don't pre-list anything. Detect by attempt + error class:

- **`Skill` (`superpowers:requesting-code-review`)**: invoke the Skill call directly. If the host returns "skill not found" / "unknown skill" or an analogous error, treat as missing and apply the fallback. Do NOT pre-check by listing skills.
- **Subagent (`code-task-agent`)**: before spawning via the `Agent` tool, check whether `code-task-agent` appears in the host's available `subagent_type` list. If you cannot enumerate the list, attempt the spawn — if the host rejects with "unknown subagent_type" or equivalent, fall back to inline implementation.

Never block the workflow on a missing optional dependency.

## Gotchas

- **Supported issue types**: Story (Full Plan), Task / Sub-task / Defect (Lite Plan). Epics are **not** supported — abort immediately.
- **Nothing executes without approval**: Jira state transitions, sub-task creation, and commits ALWAYS require explicit user confirmation.
- **Branching**: Story sub-tasks branch from the parent branch (never directly from `{{BASE_BRANCH}}`). Independent Task / Defect tickets branch from `{{BASE_BRANCH}}`. Use `scripts/create-branch.sh` to create branches.
- **Read project conventions before coding**: If the project has a `CLAUDE.md` or pattern docs, read them first. Project conventions always override generic defaults.
- **Commits follow project conventions**: No auto-commits. User approval is required for every commit.
- **Pause / Resume**: When the user requests a pause, change of approach, or abort, save state per `references/workflow-state.md` and stop. On a resume request ("resume", "continue") read the saved state and pick up from the recorded checkpoint.
