# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

This compatibility template is not a second SDD pass. Normal high-risk task review
combines spec and quality in `task-reviewer-prompt.md`. Use this only when the user
explicitly requested a separate code-quality review.

```
Codex spawn_agent (`superpowers_astra_reviewer`, `fork_turns: none`):
agent_type: superpowers_astra_reviewer
  Use template at requesting-code-review/code-reviewer.md, including its read-only
  contract and exactly one top-level verdict line:
  `Verdict: ship | fix-first | rethink`

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DIFF_FILE: [artifact from scripts/review-package PLAN_FILE BASE_SHA HEAD_SHA]
```

**In addition to standard code quality concerns, the reviewer should check:**

The reviewer performs this review itself. It must not spawn helpers or another
reviewer; the controller already scheduled the review.
It remains strictly read-only: do not create or enter worktrees and do not modify
source, branch state, or review artifacts.

- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)

**Code reviewer returns:** exactly one top-level `ship`, `fix-first`, or `rethink`
verdict, then Strengths, Issues (Critical/Important/Minor), and reasoning.
