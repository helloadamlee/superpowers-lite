---
name: executing-plans
description: Execute a written implementation plan directly or in a resumable session, scaling isolation, delegation, review, and verification to risk
---

# Executing Plans

Do not call `EnterPlanMode` or `ExitPlanMode`; this skill executes an existing plan
with normal implementation tools.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Choose Execution Mode

Controller execution is the normal default. A plan is an execution map, not a rule
that every task must be delegated.

- **Controller:** best for Direct, most Light, tightly coupled, or modest plans.
- **Routed agents:** use for genuinely independent, long, risky, parallel, or
  explicitly delegated tasks.
- **Separate/resumable session:** use when context longevity or handoff matters.

This Codex-only package follows `skills/shared/codex-routing.md`. Inspect the host's
callable tool list and select routed or single-agent mode using its host capability
gate.

In routed mode, before delegation run the platform install check
(`scripts/install-codex-agents.sh --check` on POSIX or
`.\scripts\install-codex-agents.ps1 -Check` on Windows), resolve `modelTier` with
the platform resolver, verify the exact custom `agent_type`, and use `spawn_agent`
with `fork_turns: none`. Never silently substitute another role or model.

In single-agent mode, execute directly. If the user or plan explicitly requires
subagents, parallel delegation, or independent review, stop and report that the host
does not expose the required capability. Do not call controller self-review an
independent review.

## Load and Check the Plan

1. Read the plan and requirements.
2. If present, load `<plan-path>.tasks.json`; restore native tasks only when they are
   useful for resume or delegation.
3. Resume at the first incomplete outcome. Do not recreate completed work merely
   because native task state is empty.
4. Check the plan against current source and changed facts. Raise only gaps that
   materially block or alter the implementation; resolve ordinary implementation
   detail from the repository.
5. If another live session authored the plan, consult it only for genuine intent
   ambiguity rather than guessing or reopening settled decisions.

## Decide on Isolation

Use `superpowers:using-git-worktrees` when work is parallel/multi-agent, long/risky,
explicitly isolated, or unsafe in the current checkout. Otherwise remain in the
current safe branch/workspace and preserve unrelated changes. A written plan does not make a worktree mandatory.

## Execute Outcomes

For each task or coherent outcome:

1. Mark it in progress when task tracking is in use.
2. Reconfirm the task's acceptance criteria, relevant files/symbols, interfaces, and
   risk markers against current code.
3. Implement directly or dispatch the exact routed implementer chosen by
   `modelTier`.
4. Run the task's proportional `verificationScope`:
   - `format`: formatter/parser/static validation;
   - `focused`: affected unit/module tests;
   - `dependent`: shared contract and known consumers;
   - `full`: cross-cutting/high-risk integration evidence.
5. Confirm each acceptance criterion from fresh output.
6. Mark complete and sync `.tasks.json` when persistence is in use.

Do not follow stale code snippets blindly when the current repository has evolved;
preserve the plan's goal and interfaces, and surface an architectural conflict rather
than changing it silently.

## User-Ordered Gates

For `userGate: true` or `user-gate` tasks, execute the settled method and capture
fresh evidence for every acceptance criterion. Do not substitute a cheaper check or
reopen the decision without materially changed facts.

If `requiresUserSpecification: true`, invoke `superpowers:specifying-gates`, then
return here. Leave the task in progress and surface a blocker if the named evidence
cannot be produced.

## Risk-Calibrated Review

- Direct: no independent review by default.
- Light: one final review only for substantive risk.
- Full: one fresh `superpowers_astra_reviewer` whole-diff review at the end.
- Per-task review: required at `highRiskBoundary: true` tasks before dependent work,
  absent for ordinary tasks.

When an independent review is warranted, use
`superpowers:requesting-code-review`. Mechanical findings are fixed inline with
format/static evidence and no re-review. Substantive fixes use focused, dependent,
or full verification based on blast radius; re-review only the fix diff when the fix
involves judgment or high-risk behavior.

## Completion

Run the final integration evidence appropriate to the plan. The full suite normally
runs once here, not after every task; rerun it only when a later broad fix invalidates
the result. Then use `superpowers:verification-before-completion` before claiming the
outcome.

Invoke `superpowers:finishing-a-development-branch` only when there is actually a
development branch or integration choice to finish. A documentation/configuration
edit in the current workspace does not require a branch-completion ceremony.

Stop for a true blocker, missing authority, destructive action, repeated unexplained
verification failure, or an architectural conflict. Do not stop for ordinary details
the plan and current source let you resolve safely.
