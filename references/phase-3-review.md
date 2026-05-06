# Phase 3-review — Code Review

## Run review

Attempt to invoke `superpowers:requesting-code-review` directly via the `Skill` tool — do NOT pre-list available skills:

```
Skill({ skill: "superpowers:requesting-code-review" })
```

**Detection by attempt:** if the host returns an error indicating the skill is unknown / not found / not installed (e.g. "skill not found", "unknown skill", "no such skill"), treat the dependency as missing.

If the skill is missing, skip this Phase and notify the user:
> "`superpowers:requesting-code-review` is not installed. Skipping the review step. Install the `superpowers` plugin (<https://github.com/anthropics/skills>) to enable automated code review here."

Then proceed to Phase 4.

## Result handling (when review ran)

- **No issues** → proceed to Phase 4.
- **Issues found** → summarize the review and ask:
  > "[N] issues were found. Apply fixes? (y/n)"
  - **y**: apply fixes → commit approval (Phase 3-3 procedure) → re-run `superpowers:requesting-code-review`.
  - **n**: proceed to Phase 4 (user judgment to skip).

Phase 3-review complete → read `references/phase-4-complete.md` and start Phase 4.
