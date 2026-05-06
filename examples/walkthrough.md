# Walkthrough — A Story ticket from start to finish

This walkthrough shows what an end-to-end run looks like with the skill installed and a Jira MCP server registered. Replace `ENG`, `ENG-100`, and the sub-task keys with your project's real values. Every Claude action that mutates state pauses for `y/n`.

## Setup state

- This is your **first time** running the skill in this project, so `.claude/jira-workflow-config.md` does not yet exist.
- Your Jira project key is `ENG`. The story ticket you want to develop is `ENG-100`.

## Step 1 — Trigger the skill

```
You: ENG-100 start work
```

Because there's no config, Claude reads `references/phase-0-setup.md` and runs the **first-run wizard** (after a quick MCP availability check). It asks 6 short questions:

```
Claude: 👋 First-run setup for jira-dev-workflow.
        I'll ask 6 short questions and write `.claude/jira-workflow-config.md`.
        You can edit that file later to change any value.

   1. Jira project key (the prefix in ticket numbers)?
      → ENG
   2. The exact "in progress" status name in your Jira workflow? (default: In Progress)
      →
   3. The exact "done" status name? (default: Done)
      →
   4. Branch name prefix? (default: feature)
      →
   5. Base branch you cut development branches from? (default: main)
      →
   6. Your Jira account email (used as sub-task assignee, leave blank to skip)?
      → you@example.com
```

Claude writes the config and immediately continues to Phase 1 (no extra prompt to "start").

## Step 2 — Phase 1: Analyze

Claude calls `mcp__atlassian__jira_get_issue` on `ENG-100`, validates the type (Story → Full Plan), prints the analysis, and asks for state-transition approval:

```
📋 [ENG-100] Add SAML SSO to login flow
Status: To Do
Summary: Allow customers to sign in with their identity provider via SAML 2.0…
Considerations: Need to handle session lifecycle; existing email/password
                must keep working during rollout.

Transition [ENG-100] to 'In Progress'? (y/n)
```

You: `y`. Claude transitions and proceeds to Phase 2.

## Step 3 — Phase 2: Plan

Claude decomposes the ticket into Tasks, classifies each as `large`/`small`, and offers a choice:

```
## Plan: [ENG-100] Add SAML SSO to login flow

### Task 1: Wire SAML metadata endpoint
- Targets: AuthController, SamlMetadataService (new)
- Commit type: feat
- Scope: large
- Done criteria: build passes + new endpoint returns 200

### Task 2: Plug SAML response into session issuer
- Targets: SessionIssuer
- Commit type: feat
- Scope: small
- Done criteria: existing session tests stay green

(1) Register Jira sub-tasks and run them in sequence
(2) Keep the plan only and work directly
```

You: `1`. Claude checks for existing sub-tasks, sees none, and creates `ENG-101` and `ENG-102` via `mcp__atlassian__jira_create_issue`, both assigned to you.

## Step 4 — Phase 3: Execute (Task 1 of 2)

Claude asks how to confirm Task starts:

```
Running 2 Tasks total.
(y) Confirm before each Task
(n) Auto-sequential (commit approval is ALWAYS still requested)
```

You: `n` (let it stream).

For each Task Claude runs `bash ~/.claude/skills/jira-dev-workflow/scripts/create-branch.sh ENG-100 ENG-101`. The script creates the parent branch `feature/_ENG-100/parent/ENG-100` from `main`, then the work branch `feature/_ENG-100/ENG-101` off the parent.

Because Task 1 is `large`, Claude attempts to spawn the `code-task-agent` subagent via the `Agent` tool. (If your host doesn't have `code-task-agent`, it falls back to inline implementation reading the project's `CLAUDE.md` first — same outcome.)

When done, Claude proposes a commit:

```
Commit with this message?

✨ feat: add SAML metadata endpoint

Adds /auth/saml/metadata exposing IDP-consumable metadata XML.
Wires SamlMetadataService into AuthController.

(y/n)
```

You: `y`. Claude stages only the changed files, commits, and transitions `ENG-101` to `Done`. Then asks:

```
Merge feature/_ENG-100/ENG-101 into feature/_ENG-100/parent/ENG-100? (y/n)
```

You: `y`. Same loop runs for Task 2.

## Step 5 — Phase 3: Review

Claude attempts `Skill({ skill: "superpowers:requesting-code-review" })`. If the skill is installed it runs against the parent branch's commit diff. If not installed Claude prints a one-line notice and skips. Either way you continue to Phase 4.

## Step 6 — Phase 4: Complete

Claude detects unpushed commits and asks:

```
Push to origin/feature/_ENG-100/parent/ENG-100? (y/n)
```

You: `y`. Then the final prompt:

```
Transition [ENG-100] to 'Done' and post a summary comment? (y/n)
```

You: `y`. Claude transitions the parent and posts a non-technical summary comment that PMs/POs can read directly.

Workflow done. State file `.claude/jira-workflow-state.json` is deleted.

## Pause and resume

If at any point you say "pause" or "let's revisit", Claude saves state to `.claude/jira-workflow-state.json` and stops. Type `resume` later (in the same project) and Claude continues from the recorded checkpoint — including remembering which Tasks were committed but not merged.
