# Scoped Re-Review Prompt Template

Use this template only after a substantive fix involving judgment, a shared
contract, or high-risk behavior. The
re-reviewer verifies the findings were addressed and checks the fix diff for
new breakage. It is not a fresh review — the full review already happened.

**Purpose:** Verify each finding from the previous review was addressed, and
that the fix itself broke nothing.

```
Codex spawn_agent (`superpowers_astra_reviewer`, `fork_turns: none`):
  description: "Scoped re-review of Task N substantive fix"
agent_type: superpowers_astra_reviewer
  prompt: |
    You are re-reviewing one task's substantive fix. A previous review produced
    findings; an implementer has attempted to fix them. Your job is to
    assess each finding and inspect the fix diff — nothing else.

    ## The Task

    Read the task brief: [BRIEF_FILE]

    ## The Findings Under Verification

    [FINDINGS]

    ## The Fix

    Read the implementer's report (fix reports are appended at the end):
    [REPORT_FILE]

    **Fix base:** [FIX_BASE_SHA] (the head the previous review saw)
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read the diff file once — it contains the committed fix range plus staged,
    unstaged, and untracked fix state with surrounding context. Do not re-run git
    commands. If it is missing or empty, return `rethink` and name the artifact
    failure; do not construct or write a replacement.

    Your review is read-only on this checkout. Do not create or enter worktrees and
    do not mutate the working tree, index, HEAD, branch state, or any artifact.

    ## You Do Not Dispatch Subagents

    Do this re-review yourself. Never spawn a helper or another reviewer for a
    second opinion. The controller already scheduled this review; another agent
    duplicates the review and its verdict does not count.

    ## Scope

    Your scope is the findings list and the fix diff. Assess every finding.
    Inspect the fix diff for new problems the fix itself introduced. Do NOT
    re-review code the fix did not touch: if you notice an issue entirely
    outside the fix diff, report it under Out-of-Scope Observations — it
    does not block this task and does not extend the loop. A broad
    whole-branch review happens after all tasks are complete.

    ## Tests

    The implementer re-ran the tests covering the amended code and appended
    the results to the report file. Treat the report as unverified claims:
    confirm the fix report names the covering tests and shows their output,
    and verify the claims against the diff. Do not re-run the suite to
    confirm their report. Run a test only when reading the code raises a
    specific doubt that no existing run answers — and then a focused test,
    never a package-wide suite.

    ## Output Format

    Your final message is the report itself. Every line is the single top-level
    verdict, a finding status with file:line,
    or a check you ran — no preamble, no process narration.

    Begin with exactly one top-level verdict line:

    `Verdict: ship | fix-first | rethink`

    Use `ship` when every original finding is addressed with no new blocking issue,
    `fix-first` when bounded substantive work remains, and `rethink` when the fix
    approach or artifact is structurally invalid. Do not add another readiness,
    approval, status, or fix-round verdict.

    ### Finding Statuses

    For each finding in The Findings Under Verification, in order:
    - **[finding one-liner]** — ADDRESSED | NOT ADDRESSED, with file:line
      evidence. "Attempted" is not addressed: the specific defect must no
      longer exist.

    ### New Breakage in the Fix Diff

    Anything the fix itself broke or introduced, with severity
    (Critical/Important/Minor) and file:line. Only Critical or Important
    findings inside this fix diff can keep the fix open. "None" if clean.

    ### Out-of-Scope Observations

    Issues you noticed entirely outside the fix diff. Non-blocking; the
    controller ledgers these for the final review. "None" if none.

    ### Reasoning
    [1-2 sentence technical basis for the single verdict; list open findings]
```

**Placeholders:**
- `[ROLE]` — REQUIRED: `superpowers_astra_reviewer`; never substitute another role
- `[BRIEF_FILE]` — the task brief file (same file the implementer worked from)
- `[FINDINGS]` — the Critical/Important findings and spec gaps from the
  previous review, copied verbatim, one per bullet
- `[REPORT_FILE]` — the implementer's report file (fix reports appended)
- `[FIX_BASE_SHA]` — the head the previous review saw
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — the path `scripts/review-package PLAN_FILE FIX_BASE HEAD` printed

**Re-reviewer returns:** exactly one top-level `ship`, `fix-first`, or `rethink`
verdict, then per-finding statuses (ADDRESSED / NOT ADDRESSED), new breakage in the
fix diff, out-of-scope observations, and reasoning.
