# Contributing

Thanks for your interest in improving `jira-dev-workflow`.

## Project layout

```
.
├── SKILL.md                    # Skill entry point + 4-phase index
├── references/
│   ├── phase-0-setup.md        # First-run interview wizard
│   ├── phase-1-analyze.md      # Ticket fetch + status transition
│   ├── phase-2-plan.md         # Plan + (optional) Jira sub-task creation
│   ├── phase-3-execute.md      # Task loop (Full Plan path)
│   ├── phase-3-direct.md       # Direct Work mode (Lite Plan path)
│   ├── phase-3-review.md       # Optional automated code review
│   ├── phase-4-complete.md     # Parent transition + summary comment
│   └── workflow-state.md       # Pause / resume protocol
├── agents/
│   └── code-task-agent.md      # Optional subagent for large-scope Tasks
├── scripts/
│   └── create-branch.sh        # Branch helper (uses BASE_BRANCH from config)
├── evals/
│   └── evals.json              # Trigger / non-trigger examples
└── examples/
    └── walkthrough.md          # End-to-end usage example
```

## Local development

1. Clone to your skills directory:
   ```bash
   git clone <your-fork> ~/.claude/skills/jira-dev-workflow
   ```
2. Edit files in place. Claude Code reads them on each invocation — no rebuild step.
3. Test by running through Phase 0 and Phase 1 in a throwaway project (delete `.claude/jira-workflow-config.md` to re-trigger Phase 0).

## Variable substitutions

The skill is templated. When editing prompts, use these placeholders rather than hard-coded values:

- `{{PROJECT_KEY}}` — Jira project key
- `{{IN_PROGRESS_STATUS}}` — workflow "in progress" name
- `{{DONE_STATUS}}` — workflow "done" name
- `{{BRANCH_PREFIX}}` — branch name prefix
- `{{BASE_BRANCH}}` — base branch
- `{{JIRA_USER_EMAIL}}` — assignee email (optional)

These are filled in at runtime from `.claude/jira-workflow-config.md`.

## Style guidelines

- Keep prompts in English.
- Keep each Phase short and tactical — Claude reads the file just-in-time, so being concise reduces cognitive load.
- Always preserve the **explicit user approval** gates. The skill's value comes from being predictable, not from being aggressive.
- When adding a new step, ensure it integrates with the pause / resume protocol in `workflow-state.md`.

## Submitting changes

1. Open an issue describing the change first if it's non-trivial.
2. Send a PR against `main`. Include before/after of any prompt you changed.
3. If you added a new external dependency (skill / subagent / MCP tool), document the fallback path when it's missing.

## Scope discipline

This skill is intentionally narrow:
- Jira (via MCP) + git + the four phases.
- It does **not** try to be a generic "dev workflow" tool — patches that broaden the scope (e.g. GitHub-issues mode, GitLab integration baked in) are likely out of scope unless they share the same lifecycle and approval semantics.

## License

By submitting a contribution, you agree it will be licensed under the project's [MIT license](LICENSE).
