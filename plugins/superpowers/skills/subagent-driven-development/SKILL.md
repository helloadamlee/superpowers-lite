---
name: subagent-driven-development
description: Execute a long, risky, parallel, or explicitly delegated plan with exact custom Codex roles, proportional task review, and one final whole-diff review
---

# Subagent-Driven Development

Use routed agents when delegation materially helps a long, risky, parallel, or
explicitly delegated plan. Direct and normal Light work should remain in the
controller; the existence of a plan alone is not a reason to dispatch every task.

**Core principle:** precise isolated briefs + deterministic custom roles +
risk-calibrated evidence.

Continue through the approved plan without routine "should I continue?" pauses.
Stop only for a real blocker, missing authority, architectural conflict, or ambiguity
that would materially change the result.

## Host Capability Gate

This skill requires routed mode from `skills/shared/codex-routing.md`. Inspect the
host's callable tool list and confirm `spawn_agent` is callable. If absent, use
`superpowers:executing-plans` for controller execution when allowed, or stop if the
user explicitly requires delegation or independent review. Never claim this workflow
ran in single-agent mode.

## When to Use

Use this skill when tasks are meaningfully independent and at least one applies:

- work is long enough that isolated task context improves reliability;
- risk justifies specialist implementation or independent review;
- disjoint tasks can run in parallel;
- the user explicitly requested subagents or the routed custom roles.

Do not use it for a handful of tightly coupled edits that the controller can hold in
context. `superpowers:executing-plans` is the lighter default.

## Setup

Read the plan once and identify constraints, dependencies, risk markers, and
verification scopes. Use native tasks and `<plan>.tasks.json` when they help resume or
coordination; do not recreate completed work.

Commands written as `scripts/...` below are relative to the installed Superpowers
plugin root. Resolve them to absolute paths from this loaded skill; do not look for
them in the user's project. Keep the user's project or worktree as the command's
working directory.

Use `superpowers:using-git-worktrees`: multi-agent writers require isolation. Follow
global/repository bootstrap and cleanup lifecycle instructions exactly.

For long or resumable work, run `scripts/sdd-workspace PLAN_FILE`. Keep the plan's
ledger at `<workspace>/progress.md` with first line:

```markdown
# SDD ledger — plan: <plan file path>
```

The ledger is a compact recovery map, not a diary. Record dispatch, completion,
substantive fix, parked finding, and blocker events in one line each. Trust the
ledger and Git history after compaction. Never reuse another plan's workspace.

## Deterministic Codex Role Routing

Resolve task `modelTier` with `scripts/resolve-codex-role.sh` on POSIX or
`.\scripts\resolve-codex-role.ps1` on Windows:

- `mechanical` -> `superpowers_luna_implementer` (`gpt-5.6-luna`, medium)
- `standard` -> `superpowers_terra_implementer` (`gpt-5.6-terra`, high)
- `frontier` -> `superpowers_astra_implementer` (`gpt-6-astra`, high)
- independent review -> `superpowers_astra_reviewer` (`gpt-6-astra`, high, read-only)

Before each dispatch, run `scripts/install-codex-agents.sh --check` on POSIX or
`.\scripts\install-codex-agents.ps1 -Check` on Windows and verify the exact role is
exposed. Dispatch with `spawn_agent` and `fork_turns: none`. Do not pass a raw model
or inherit controller history.

If a role/model is missing, unavailable, or launches incorrectly, report the exact
role, model, tier, effort, observed failure, and check command. Offer only restoring
access, explicitly changing and recording the tier, or stopping. Do not retry with a
different role: never silently substitute.

## Dispatch a Task

1. Record the base SHA before implementation.
2. Run `scripts/task-brief PLAN_FILE N`; its output file is the task's requirements
   source.
3. Give the implementer:
   - one line of project context;
   - the brief path and instruction to read it first;
   - only interfaces/decisions from prior tasks that the brief cannot know;
   - a report-file path beside the brief;
   - the exact owned file set and reminder that other agents may be working.
4. Use [implementer-prompt.md](implementer-prompt.md). The implementer performs its
   own focused self-check, proportional verification, and reports status, commits,
   evidence summary, and concerns. It does not dispatch reviewers.
5. Answer `NEEDS_CONTEXT` with missing facts. For `BLOCKED`, change something real:
   provide context, split scope, explicitly raise `modelTier`, or surface a flawed
   plan. Do not retry unchanged instructions.

Do not paste accumulated session history into later dispatches. Artifacts carry
requirements and evidence without polluting controller context.

## Proportional Task Verification

Require fresh evidence before marking a task complete:

- `format`: formatter/parser/static validation;
- `focused`: affected unit/module checks;
- `dependent`: shared API and known consumers;
- `full`: security, concurrency, persistence/migration, or broad integration work.

The implementer runs the selected evidence and names its command/output in the report.
The controller inspects the report and actual diff, verifies each acceptance
criterion, and reruns only evidence that is missing, doubtful, or invalidated by a
later change. Do not repeat every worker command or rerun a full suite after every
task. The full suite normally runs once at the final integration boundary.

## Risk-Triggered Task Review

Per-task independent review is REQUIRED only when the task is explicitly marked
`highRiskBoundary: true`. Valid reasons to set that marker are:

- security/authentication/authorization;
- concurrency/synchronization;
- persistence, destructive data handling, or migration;
- public API, wire protocol, or compatibility contract;
- broad shared infrastructure;
- explicitly required by the user.

For ordinary tasks without the marker, implementer evidence plus controller
acceptance is sufficient; independent task review is absent. Append completion and
continue. Delegation does not make every task a review boundary.

For a high-risk boundary:

1. After the implementation report lands, run
   `scripts/review-package PLAN_FILE BASE HEAD`.
2. Dispatch one fresh `superpowers_astra_reviewer` using
   [task-reviewer-prompt.md](task-reviewer-prompt.md), combining specification and
   code-quality review in a single pass.
3. Give it the brief, report, review-package path, and only the load-bearing global
   constraints. Do not ask it to rerun evidence already captured unless the diff
   creates a specific unanswered doubt.

## Findings and Fixes

Validate each finding against current source and requirements, then classify by fix
blast radius:

- **Mechanical/trivial:** formatting, comment, punctuation, import cleanup, or an
  obvious no-judgment correction. The controller or implementer fixes it inline,
  runs format/static evidence, and does not re-review.
- **Localized substantive:** resume the implementer, run focused tests, and re-review
  only if the fix involves meaningful judgment or the finding cannot be verified
  directly.
- **Shared contract:** resume the implementer, run dependent evidence, and dispatch
  one scoped re-review of the fix diff.
- **Security/concurrency/persistence/migration/cross-cutting:** use the appropriate
  implementer tier, run full relevant evidence, and dispatch one scoped re-review.

Use [re-review-prompt.md](re-review-prompt.md) only for substantive fixes that meet
those criteria. Generate its package with
`scripts/review-package PLAN_FILE FIX_BASE HEAD`. A scoped re-review checks the
original substantive findings and the fix diff. New findings reopen work only when
they are inside the fix diff and Critical or Important; unrelated or Minor notes are
recorded for the final review without another loop.

There is one substantive fix wave per task review. If a load-bearing finding remains
after its scoped re-review, surface it as blocked rather than starting repeated
review/fix rounds. A disputed or non-load-bearing point may be parked with a concise
technical ruling for the final reviewer.

## Complete a Task

Mark complete when acceptance criteria have fresh proportional evidence and any
required high-risk review has no open load-bearing finding. Append a compact ledger
entry and sync `<plan>.tasks.json` if used.

Never require a commit per task unless project/user instructions do. `review-package`
includes the committed range, index, working tree, and untracked files, so an
independent review remains non-empty when `BASE == HEAD` or work is uncommitted.

## Final Whole-Diff Review

Full delegated work gets exactly one fresh independent whole-diff review after all
tasks pass their selected evidence:

1. Run `scripts/review-package PLAN_FILE MERGE_BASE HEAD`.
2. Dispatch `superpowers_astra_reviewer` with
   [../requesting-code-review/code-reviewer.md](../requesting-code-review/code-reviewer.md).
3. Point it at the complete diff, requirements, risk boundaries, and evidence summary.

If it returns findings, group them into one fix wave. Mechanical fixes receive only
format/static evidence and no re-review. Substantive fixes receive evidence matching
their blast radius and at most one scoped re-review of the fix diff. Residual
load-bearing findings are surfaced to the user; do not start a second whole-diff
review.

The final full suite runs once at the integration boundary unless a broad subsequent
fix invalidates it. A tiny mechanical correction does not invalidate behavioral test
evidence.

## Parallel Dispatch

Read-only agents are parallel-safe. Write-capable implementers may run concurrently
only when their declared file sets are disjoint and neither depends on the other.
Never run two writers on one file. Mark tracked tasks in progress before dispatch and
serialize when overlap is uncertain.

Parallel execution does not add per-task review. The same high-risk-boundary rule and
single final whole-diff review apply.

## Finish

Use `superpowers:verification-before-completion` on the integrated tree. Then invoke
`superpowers:finishing-a-development-branch` when a real branch/integration decision
exists. Run the required worktree cleanup lifecycle before removal and delete only
this plan's temporary workspace after its durable evidence lives in Git or the final
report.
