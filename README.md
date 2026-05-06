# jira-dev-workflow

A [Claude Code](https://claude.com/claude-code) skill that drives a Jira story ticket through the full development lifecycle — analyze, plan, implement, complete — with explicit user approvals at every gate.

> "ENG-100 start work" → Claude reads the ticket, drafts a Task plan, registers Jira sub-tasks, runs each Task on its own branch, commits with the right message, transitions Jira states, and posts a final summary comment on the parent ticket.

## TL;DR

```bash
# 1. Install a Jira MCP server (sooperset/mcp-atlassian recommended), register it as `atlassian`
# 2. Install this skill
git clone https://github.com/toyunity/jira-dev-workflow.git ~/.claude/skills/jira-dev-workflow
# 3. (Optional) Install the bundled code-task-agent for large-scope Tasks
cp ~/.claude/skills/jira-dev-workflow/agents/code-task-agent.md ~/.claude/agents/
# 4. In any project, type:
#    "ENG-100 start work"
# Claude walks you through the full flow with y/n gates.
```

First run in a project triggers a 6-question setup wizard that writes `.claude/jira-workflow-config.md` — edit that file later to tweak any value.

## 1. Overview

Most teams already have the conventions: ticket numbering, branch naming, commit message style, and a Jira state machine for in-progress / done. This skill encodes that lifecycle into Claude Code so you can hand it a ticket key and get back reviewed, committed, status-updated work — without writing a fresh prompt every time.

The skill never executes anything destructive without your `y/n`. State transitions, sub-task creation, commits, merges, and pushes are each gated.

## 2. Demo

A full Story-ticket walkthrough (with sub-task creation, branching, commit, merge, review, and parent-ticket completion) is in [`examples/walkthrough.md`](examples/walkthrough.md).

Demo recording / screenshots TBD — drop a GIF or asciinema link here once you've recorded a run.

## 3. Prerequisites

### Required

- [Claude Code CLI](https://claude.com/claude-code) installed.
- **A Jira MCP server**, registered with Claude Code under the server name `atlassian` (so its tools resolve as `mcp__atlassian__jira_*`). **The skill cannot run without this** — every Phase calls Jira through MCP. Recommended: [`sooperset/mcp-atlassian`](https://github.com/sooperset/mcp-atlassian).
- Atlassian Cloud, Server, and Data Center are all supported — the MCP layer abstracts the differences. Choose any Jira MCP server that's compatible with your deployment.

  The skill specifically uses these tools:

  ```
  mcp__atlassian__jira_get_issue
  mcp__atlassian__jira_get_transitions
  mcp__atlassian__jira_transition_issue
  mcp__atlassian__jira_create_issue
  mcp__atlassian__jira_add_comment
  mcp__atlassian__jira_get_user_profile
  mcp__atlassian__jira_get_issues_development_info
  ```

  If you invoke the skill before the MCP server is configured, Phase 0 aborts with setup instructions — no other state is changed.

### Optional (the skill falls back gracefully if missing)

- [`superpowers`](https://github.com/anthropics/skills) plugin — enables an automated code-review step in Phase 3.
- `code-task-agent` subagent — used for large-scope Tasks. **Bundled in this repo at `agents/code-task-agent.md`** — see Installation Step 3 below to enable it. Without it, large Tasks are implemented inline.

## 4. Installation

### Step 1 — Set up the Jira MCP server (required, do this first)

Pick any Jira MCP server compatible with Claude Code. The reference choice is [`sooperset/mcp-atlassian`](https://github.com/sooperset/mcp-atlassian). Follow that project's README to:

1. Install the server (typically via `uvx` / `pipx` / Docker).
2. Configure your Atlassian credentials (URL, email, API token).
3. **Register the server with Claude Code under the server name `atlassian`.** This is critical — Claude Code namespaces MCP tools as `mcp__<server-name>__<tool-name>`, and this skill is wired against the `atlassian` namespace. Use:
   ```bash
   claude mcp add atlassian -- <command-to-launch-server>
   ```
   (or set `"atlassian"` as the key in your MCP config file).
4. Verify in a Claude Code session that tools named `mcp__atlassian__jira_*` appear (`/mcp` lists registered servers, the tool list shows registered tools).

If you've registered the server under a different name (e.g. `jira`, `mcp-atlassian`), the skill won't find its tools. Re-register it as `atlassian` or fork this skill and rename the prefix throughout `references/`.

If `mcp__atlassian__jira_*` tools don't appear in a fresh Claude Code session, **don't proceed** — the skill will only abort with a setup prompt.

### Step 2 — Install this skill

> **Heads-up:** if `~/.claude/skills/jira-dev-workflow/` already exists (e.g. from an earlier version, a fork, or another locale of this skill), back it up or remove it before cloning. `git clone` will refuse to write into a non-empty directory.
> ```bash
> [ -d ~/.claude/skills/jira-dev-workflow ] && \
>   mv ~/.claude/skills/jira-dev-workflow ~/.claude/skills/jira-dev-workflow.bak.$(date +%s)
> ```

Clone into your Claude Code skills directory:

```bash
git clone https://github.com/toyunity/jira-dev-workflow.git \
  ~/.claude/skills/jira-dev-workflow
```

Restart your Claude Code session (or run `/skills` and confirm `jira-dev-workflow` appears).

That installs the skill globally for your user. To install per-project instead, clone to `<project>/.claude/skills/jira-dev-workflow` — Claude Code picks up project-local skills automatically. (Note: if you install per-project, the absolute paths to `scripts/create-branch.sh` referenced in `references/` will need adjustment.)

### Step 3 — (Optional) Install the bundled `code-task-agent`

Phase 3 of the workflow can offload large-scope Tasks to a `code-task-agent` subagent for isolated, structured implementation. This repo ships a build-tool-agnostic version of that agent at `agents/code-task-agent.md`. To enable it:

```bash
mkdir -p ~/.claude/agents
cp ~/.claude/skills/jira-dev-workflow/agents/code-task-agent.md ~/.claude/agents/
```

Restart your Claude Code session. The skill will now use this agent for large-scope Tasks; without it, the same Tasks are implemented inline in the main session (slower context but identical outcome).

The bundled agent reads your project's `CLAUDE.md` (or `AGENTS.md`/`.cursorrules`) for build/test commands and conventions, and falls back to a conservative auto-detection table for common build files (Gradle, Maven, npm, Cargo, Go modules, pyproject). If your project has a non-standard build setup, document the build/test commands in your `CLAUDE.md` and the agent will pick them up.

## 5. First-run Setup

The first time you trigger the skill in a project, it asks 6 short questions and writes `.claude/jira-workflow-config.md` in that project's root.

| Field | Purpose | Default | Example |
|-------|---------|---------|---------|
| `PROJECT_KEY` | Ticket prefix | — (required) | `ENG` |
| `IN_PROGRESS_STATUS` | "In progress" Jira status name | `In Progress` | `Doing` |
| `DONE_STATUS` | "Done" Jira status name | `Done` | `Completed` |
| `BRANCH_PREFIX` | Branch name prefix | `feature` | `feat` |
| `BASE_BRANCH` | Base branch for development | `main` | `develop` |
| `JIRA_USER_EMAIL` | Sub-task assignee email | (empty → unassigned) | `you@example.com` |

You can edit `.claude/jira-workflow-config.md` later to tweak any value, or ask Claude to "reconfigure jira-workflow".

## 6. Usage

In any project, type any of these to Claude Code:

```
ENG-100 start work
begin development on ENG-512
let's tackle ENG-399
```

The skill walks through 4 phases. Each phase pauses for your approval before doing anything that mutates state.

To pause mid-flow, just say so ("pause", "stop", "let's revisit"). State is saved to `.claude/jira-workflow-state.json`. Resume anytime with "resume" or "continue".

## 7. Configuration

`.claude/jira-workflow-config.md` (per-project) drives the skill's variable substitutions. Sample:

```markdown
# Jira Dev Workflow Config

PROJECT_KEY: ENG
IN_PROGRESS_STATUS: In Progress
DONE_STATUS: Done
BRANCH_PREFIX: feature
BASE_BRANCH: main
JIRA_USER_EMAIL: you@example.com
```

Edit the file directly, or re-run the wizard by asking Claude to "reconfigure jira-workflow".

`IN_PROGRESS_STATUS` and `DONE_STATUS` must match the **exact** transition names in your Jira workflow (case-sensitive, language-sensitive). If you're not sure, ask Claude to call `mcp__atlassian__jira_get_transitions` on any ticket in your project — it lists them.

## 8. How It Works

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 0 (first run only): write config from interview       │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: fetch ticket → validate type → transition to       │
│          IN_PROGRESS_STATUS (with approval)                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: decompose into Tasks → register Jira sub-tasks     │
│          (Full Plan) or skip and work directly (Lite Plan)  │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: per Task: branch → code → commit → transition →    │
│          merge. Optional code-review step at the end.       │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 4: parent ticket to DONE_STATUS + summary comment     │
└─────────────────────────────────────────────────────────────┘
```

**Issue type behavior**

| Type | Mode |
|------|------|
| Story | Full Plan — sub-tasks registered, executed in sequence |
| Task / Sub-task / Defect | Lite Plan — Direct Work mode |
| Epic | Not supported (skill aborts) |

**Branch naming**

| Type | Pattern |
|------|---------|
| Story sub-task | `{BRANCH_PREFIX}/_{PROJECT_KEY}-{parent}/{PROJECT_KEY}-{sub}` |
| Story parent | `{BRANCH_PREFIX}/_{PROJECT_KEY}-{parent}/parent/{PROJECT_KEY}-{parent}` |
| Task / Defect | `{BRANCH_PREFIX}/{PROJECT_KEY}-{ticket}` |

## 9. Optional Dependencies

| Dependency | Used by | Source | When missing |
|------------|---------|--------|--------------|
| `superpowers:requesting-code-review` skill | Phase 3 review step | [`superpowers` plugin](https://github.com/anthropics/skills) | The review step is skipped with a notice |
| `code-task-agent` subagent | Phase 3 large-scope Tasks | Bundled — `agents/code-task-agent.md` (Installation Step 3) | The Task is implemented inline in the main session |

The skill detects availability at the relevant Phase entry points by attempting the call and classifying the error — no pre-listing.

## 10. Contributing

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The skill is intentionally small and convention-driven; the main value lies in the Phase prompts under `references/`.

## 11. License

[MIT](LICENSE) © toyunity
