# Phase 2 — Task Planning & Sub-task Creation

## Full Plan Mode (Story)

1. Decompose the ticket into Task units (one Task = one commit's worth of work) and print in this format:

   ```
   ## Plan: [{{PROJECT_KEY}}-XXX] [Title]

   ### Task 1: [Name]
   - Description: [Concrete description]
   - Targets: [Files / classes]
   - Commit type: feat / fix / refactor / etc.
   - Scope: large (≥3 files modified or created, OR adds a new Controller/Service/Repository class) / small (otherwise)
   - Done criteria: [Verifiable conditions — e.g. "build passes + related tests green"]

   ### Task 2: [Name]
   ...
   ```

2. Offer the user a choice:
   > "(1) Register Jira sub-tasks and run them in sequence  (2) Keep the plan only and work directly"
   - **If (2) is chosen**: read `references/phase-3-direct.md` and start Direct mode.

3. (1) chosen — check existing sub-tasks:
   - `mcp__atlassian__jira_get_issue` on the parent ticket with `fields="summary,status,issuetype,subtasks"`.
   - **No existing sub-tasks** → go to step 4 (create everything).
   - **Existing sub-tasks present** → go to step 3a.

3a. Compare and map existing sub-tasks against the new plan:

- Attempt automatic mapping by `summary` similarity.
- Print a comparison table:

     ```
     ## Existing sub-tasks vs new plan

     | # | Plan Task | Mapped existing ticket | State |
     |---|-----------|------------------------|-------|
     | 1 | Task 1: [Name] | {{PROJECT_KEY}}-AAA: [Title] | Reuse ✅ |
     | 2 | Task 2: [Name] | — | New 🆕 |
     | 3 | Task 3: [Name] | {{PROJECT_KEY}}-BBB: [Title] | Reuse ✅ |
     ```

- Confirm with the user:
     > "Does this mapping look right? Reuse the matched tickets and only create new ones for the rest? (y/edit/new-all)"
  - **y**: Lock the mapping — reuse mapped tickets, create only the unmapped Tasks in step 4.
  - **edit**: User specifies the mapping manually, then proceed as `y`.
  - **new-all**: Ignore existing sub-tasks — create all Tasks in step 4.

1. Create only the Tasks that need new tickets via `mcp__atlassian__jira_create_issue`:
   - Issue Type: the sub-task type name as it appears in your Jira instance (English: `Sub-task`; localized instances may use a different label — use whatever `mcp__atlassian__jira_get_issue` returns for an existing sub-task)
   - Parent: the story ticket
   - Summary: Task name
   - Description: Concrete description, target files / classes, done criteria
   - Assignee: the `accountId` resolved in Phase 1 (omit if `{{JIRA_USER_EMAIL}}` was unset)

2. Print the completion table (Phase 3 will iterate over this):

   ```
   ## Phase 2 complete — Task list
   | # | Ticket | Name | Scope | Note |
   |---|--------|------|-------|------|
   | 1 | {{PROJECT_KEY}}-YYY | Task 1: [Name] | large/small | reused |
   | 2 | {{PROJECT_KEY}}-ZZZ | Task 2: [Name] | large/small | new |
   ```

Full Plan Mode complete → read `references/phase-3-execute.md` and start Phase 3.

---

## Lite Plan Mode (Task / Sub-task / Defect)

1. Decompose into Tasks and print:

   ```
   ## Plan: [{{PROJECT_KEY}}-XXX] [Title]

   ### Task 1: [Name]
   - Description: [Concrete description]
   - Targets: [Files / classes]
   - Commit type: feat / fix / refactor / etc.
   - Scope: large (≥3 files modified or created, OR adds a new Controller/Service/Repository class) / small (otherwise)
   - Done criteria: [Verifiable conditions — e.g. "build passes + related tests green"]

   ### Task 2: [Name]
   ...
   ```

2. Ask the user:
   > "Proceed with this plan? (y/n)"

3. On approval → read `references/phase-3-direct.md` and start Direct mode.
