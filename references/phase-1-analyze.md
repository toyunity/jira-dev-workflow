# Phase 1 — Ticket Analysis & Status Transition

## Tool naming

The Jira MCP tools use their actual registered names in the form `mcp__atlassian__jira_*`.
For example: `mcp__atlassian__jira_get_issue`, `mcp__atlassian__jira_get_transitions`, `mcp__atlassian__jira_transition_issue`.

## Steps

0. Check whether `.claude/jira-workflow-state.json` exists:
   - If it exists and `parentTicket` differs from the current request:
     > "A previous workflow ([{{PROJECT_KEY}}-YYY]) is saved. Overwrite and start fresh? (y/n)"
   - On rejection, abort: "Type 'resume' to continue the saved workflow."
   - On approval, delete the existing file and continue.

1. Fetch the ticket via `mcp__atlassian__jira_get_issue`
   (pass `comment_limit=0` — comments are not needed in Phase 1).

2. **Validate the issue type**:
   - **Story** → Phase 2 (Full Plan Mode)
   - **Task / Sub-task / Defect** → Phase 2 (Lite Plan Mode):
     > "This ticket is of type [type]. We'll start by drafting a task plan."
   - **Epic** → abort immediately:
     > "Epics are not supported. Run each child story individually."

3. Resolve the current user's `accountId` for sub-task assignee:
   - If `{{JIRA_USER_EMAIL}}` is set in config:
     `mcp__atlassian__jira_get_user_profile` with `user_identifier: "{{JIRA_USER_EMAIL}}"` → store `accountId`
   - If not set, leave assignee unset and notify the user once:
     > "JIRA_USER_EMAIL is not configured. Sub-tasks will be created unassigned. Edit `.claude/jira-workflow-config.md` to set it."

4. Fetch the available transitions via `mcp__atlassian__jira_get_transitions`:
   - Extract the `{{IN_PROGRESS_STATUS}}` transition_id → save to `workflow-state.json` at `transitions.in_progress`.
   - Extract the `{{DONE_STATUS}}` transition_id → save to `workflow-state.json` at `transitions.done`.
   - If the `{{IN_PROGRESS_STATUS}}` transition is missing, print the available transitions list and abort.
   - ⚠️ For child tickets, call `get_transitions` again on each child ticket — Jira workflows can differ per issue type.

5. Print the analysis result:
   ```
   📋 [{{PROJECT_KEY}}-XXX] [Title]
   Status: [Current status]
   Summary: [2–3 lines]
   Considerations: [Technical notes]
   ```

6. If the current status is already `{{IN_PROGRESS_STATUS}}`, skip step 7.

7. Ask the user:
   > "Transition [{{PROJECT_KEY}}-XXX] to '{{IN_PROGRESS_STATUS}}'? (y/n)"
   - On approval: `mcp__atlassian__jira_transition_issue` with the saved transition_id.

Phase 1 complete → read `references/phase-2-plan.md` and start Phase 2.
