# Phase 0 — First-run Setup Wizard

Runs once per project the first time the user invokes this skill in a project that lacks `.claude/jira-workflow-config.md`.

## Trigger

SKILL.md detects the missing config and reads this file.

## Pre-flight: verify the Jira MCP server

**Before showing the wizard**, verify the Atlassian Jira MCP tools are available in this Claude Code session. The skill is non-functional without them and there is no point gathering config that can never be used.

How to check (tool-list inspection only):

- Inspect the available tool list for any tool name matching `mcp__atlassian__jira_*`. The minimum requirement is `mcp__atlassian__jira_get_issue`.
- Do **not** try to make a real Jira call here. At this point no ticket key has been provided, so any synthetic call would be guessing. Real connectivity is implicitly verified in Phase 1 against the user's actual ticket.
- If your host registered the MCP server under a different name (e.g. `mcp__jira__*` instead of `mcp__atlassian__*`), tell the user how to re-register it as `atlassian` and abort. The skill assumes the `atlassian` server name (see README §4 Step 1).

If the MCP is missing, **abort the wizard** with this message and stop:

```
❌ Atlassian Jira MCP is not configured.

This skill drives Jira through MCP tools (`mcp__atlassian__jira_*`).
Without them no Phase can run, so first-run setup is paused.

Setup steps:
  1. Install a Jira MCP server — for example:
     https://github.com/sooperset/mcp-atlassian
  2. Register it with Claude Code so tools named `mcp__atlassian__jira_*`
     appear in the tool list.
  3. Re-invoke this skill (e.g. "ENG-100 start work") to resume setup.
```

Only proceed to the wizard once an `mcp__atlassian__jira_*` tool is confirmed available.

## Wizard

Print this to the user:

```
👋 First-run setup for jira-dev-workflow.

I'll ask 6 short questions and write `.claude/jira-workflow-config.md`.
You can edit that file later to change any value.
```

Ask each question via `AskUserQuestion` (or, if that tool is unavailable in the host, ask one at a time with `(default: <value>)` and accept blank-for-default).

| # | Field | Question | Default | Examples |
|---|-------|----------|---------|----------|
| 1 | `PROJECT_KEY` | Jira project key (the prefix in ticket numbers) | — (required) | `ENG`, `DEV`, `PROJ` |
| 2 | `IN_PROGRESS_STATUS` | The exact "in progress" status name in your Jira workflow | `In Progress` | `In Progress`, `Doing`, or its localized name in your Jira (e.g. `업무진행` for Korean) |
| 3 | `DONE_STATUS` | The exact "done" status name in your Jira workflow | `Done` | `Done`, `Completed`, or its localized name (e.g. `개발완료` for Korean) |
| 4 | `BRANCH_PREFIX` | Branch name prefix | `feature` | `feature`, `feat`, `task` |
| 5 | `BASE_BRANCH` | Base branch you cut development branches from | `main` | `main`, `dev`, `develop` |
| 6 | `JIRA_USER_EMAIL` | Your Jira account email (used as sub-task assignee). Leave blank to skip. | (empty) | `you@example.com` |

> Status names must match your Jira workflow **exactly** (case- and language-sensitive). Non-English Jira instances are fully supported — just enter the actual transition name your project uses.

### Validation

- `PROJECT_KEY` — required, uppercase letters / digits, length ≥ 2 (e.g. `^[A-Z][A-Z0-9]+$`).
- `IN_PROGRESS_STATUS` and `DONE_STATUS` — must be non-empty strings. Tell the user these must match the **exact** names in their Jira workflow (case-sensitive). If unsure, they can run `mcp__atlassian__jira_get_transitions` against any ticket in the project to discover them.
- `BRANCH_PREFIX` and `BASE_BRANCH` — must be valid git ref-name fragments (no spaces / control chars).
- `JIRA_USER_EMAIL` — optional. If provided, must look like an email; otherwise leave blank.

If any required field fails validation, re-ask only that field.

## Generate the config

Write `.claude/jira-workflow-config.md` (create the `.claude` directory if missing):

```markdown
# Jira Dev Workflow Config

PROJECT_KEY: <answer 1>
IN_PROGRESS_STATUS: <answer 2>
DONE_STATUS: <answer 3>
BRANCH_PREFIX: <answer 4>
BASE_BRANCH: <answer 5>
JIRA_USER_EMAIL: <answer 6 or empty>
```

Then print a summary:

```
✅ Config written to .claude/jira-workflow-config.md

  PROJECT_KEY        = <…>
  IN_PROGRESS_STATUS = <…>
  DONE_STATUS        = <…>
  BRANCH_PREFIX      = <…>
  BASE_BRANCH        = <…>
  JIRA_USER_EMAIL    = <… | (unset)>

Edit that file anytime to change values.
```

## Hand-off

After writing the config, immediately load these values as the substitutions for `{{PROJECT_KEY}}`, `{{IN_PROGRESS_STATUS}}`, `{{DONE_STATUS}}`, `{{BRANCH_PREFIX}}`, `{{BASE_BRANCH}}`, `{{JIRA_USER_EMAIL}}` and continue to **Phase 1** (`references/phase-1-analyze.md`).

Do **not** re-prompt the user to start Phase 1 — the wizard's purpose is to keep flow uninterrupted.

## Re-running setup

If the user asks to "reconfigure" / "re-setup" / "edit jira-workflow config":

1. Read the existing `.claude/jira-workflow-config.md` and show the current values.
2. Run the wizard again with the existing values as defaults.
3. Overwrite the file.
