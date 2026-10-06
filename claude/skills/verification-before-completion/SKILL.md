---
name: verification-before-completion
description: Use before claiming work is complete, fixed, or passing, and before committing or opening a PR, to confirm the claim with fresh, applicable evidence
---

# Verification Before Completion

A completion claim is only as good as the evidence behind it. Before saying work is
done, fixed, or passing, run the check that would show it is not, read the output, and
report what it actually says. Confidence and a plausible diff are not evidence, and
users act on the claim.

## The Gate

Before any status claim, and before committing, pushing, or opening a PR:

1. **Identify** the check that proves the claim. Pick the cheapest check that could
   actually catch the mistake: a parser, formatter, type checker, focused test, smoke
   run, or the full suite, scaled to the change's blast radius.
2. **Run** it fresh, in this session, against the current state of the code.
3. **Read** the whole result: exit code, failure count, warnings.
4. **Compare** the result to the claim. If it does not support the claim, report the
   real status with the output. If it does, make the claim and cite the evidence.

Evidence goes stale when later edits touch what it covered. Rerun what a later change
invalidated; do not rerun everything out of habit.

## What Counts as Evidence

| Claim | Evidence | Not enough |
| --- | --- | --- |
| Tests pass | Test command output with 0 failures | An earlier run, "should pass" |
| Linter clean | Linter output with 0 errors | A partial check, extrapolation |
| Build succeeds | Build command exit 0 | Lint passing, logs that look fine |
| Bug fixed | The original symptom no longer reproduces | The code changed, so it is assumed fixed |
| Regression test works | It failed without the fix and passes with it | It passed once |
| Delegated work done | The actual diff and the checks you ran on it | The agent reported success |
| Requirements met | A line-by-line check against the requirements | Tests passing |

A regression test is confirmed by a red-green cycle: write it, see it pass, revert the
fix, see it fail for the expected reason, restore the fix, see it pass.

## Signs the Claim Is Ahead of the Evidence

- Hedged language ("should", "probably", "seems to") about something you could check.
- Satisfaction or a "done" before any check has run.
- About to commit, push, or open a PR without having verified.
- Relying on an agent's success report or a partial check.
- Wanting the work to be over.

When you notice one, run the check. If a check cannot be run (no environment, missing
dependency, too expensive), say so and report the claim as unverified rather than
omitting the gap.

## Reporting

State what you ran, what it returned, and what remains unverified. Failures and skipped
checks belong in the report as plainly as passes do.

For delegated work, inspect the diff and the worker's evidence first, verify each
acceptance criterion, and report the actual state of the tree.

For requirements, re-read the plan or request, build a checklist, check each item, and
report gaps or completion. Passing tests alone do not show a phase is complete.
