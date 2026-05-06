# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-05-06

### Added

- Initial public release.
- 4-Phase workflow: analyze → plan → implement → complete, gated by per-step user approvals.
- First-run interview wizard at `references/phase-0-setup.md` that writes per-project config.
- Per-project config file `.claude/jira-workflow-config.md` with 6 substitution variables: `PROJECT_KEY`, `IN_PROGRESS_STATUS`, `DONE_STATUS`, `BRANCH_PREFIX`, `BASE_BRANCH`, `JIRA_USER_EMAIL`.
- Optional integrations with `superpowers:requesting-code-review` (skill) and `code-task-agent` (subagent), each with a documented fallback when missing.
- Bundled `code-task-agent` definition at `agents/code-task-agent.md` — build-tool-agnostic, English, ready to install into `~/.claude/agents/`.
- `scripts/create-branch.sh` resolves `BRANCH_PREFIX` and `BASE_BRANCH` from env, then config file, then defaults.
- Pause / resume protocol via `.claude/jira-workflow-state.json`.
- Atlassian Cloud / Server / Data Center support via the MCP layer.

### Known issues

- `scripts/create-branch.sh` calls `git fetch origin` / `git pull origin` unconditionally — this fails on local-only repos or while offline. Inherited from the pre-OSS version. Track a graceful-skip fix in a future minor release.

[Unreleased]: https://github.com/toyunity/jira-dev-workflow/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/toyunity/jira-dev-workflow/releases/tag/v0.1.0
