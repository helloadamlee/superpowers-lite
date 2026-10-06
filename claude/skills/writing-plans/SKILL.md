---
name: writing-plans
description: Use when complex, long, risky, cross-session, or explicitly planned work needs a durable outcome-oriented implementation plan
---

# Writing Plans

Create a durable execution map, not a transcript of code the executor could discover
more reliably from the repository. Use this for Full-lane work and whenever scale,
risk, delegation, or cross-session recovery makes a persisted plan useful. Direct
and normal Light work should usually stay in the controller without invoking this
skill.

Plans carry `modelTier` metadata (mechanical, standard, or frontier) that the routing
contract resolves to a subagent. Name a tier, not a model: the agent files own the
model policy, so plans keep working when it changes.

Do not call `EnterPlanMode` or `ExitPlanMode`; write the plan with normal file and
task tools.

**Announce at start:** "I'm using the writing-plans skill to create an
outcome-oriented implementation plan."

Save to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` unless the user or
project specifies another location. Persist native task data only when another
session, agent, or resumable workflow will consume it.

## Explore Before Decomposing

Read the spec or requirements and inspect the relevant repository context before
locking in files or task boundaries. Use the repository's required structural and
semantic search tools first. Do not require `TaskList` before exploration.

If the work contains independent projects rather than one coherent deliverable,
split the plan. Follow established structure; include targeted restructuring only
when the requested outcome needs it.

## Required Plan Content

Every plan records:

- **Goal:** the observable outcome.
- **Spec (when one exists):** the repository-relative or absolute path to the
  approved design/requirements document. Keep it linked rather than duplicating it;
  do not create a spec just to populate this field.
- **Constraints and decisions:** user choices, compatibility requirements, scope
  exclusions, and invariants.
- **Approach:** a concise architectural summary and important data flow.
- **Relevant files and symbols:** likely create/modify/test locations. Mark uncertain
  locations as discovery points instead of inventing line numbers or APIs.
- **Tasks:** coherent outcomes with dependencies where they matter.
- **Acceptance criteria:** concrete externally observable or behavior-level results.
- **Verification:** focused commands or manual/smoke evidence, plus the final
  integration check when warranted.
- **Pitfalls and interfaces:** load-bearing contracts, migration concerns, security,
  concurrency, persistence, public APIs, or shared infrastructure risks.

Use code blocks, exact signatures, and step-by-step red/green instructions only when
they are load-bearing: a subtle algorithm, wire format, migration order, fragile
command, or interface another task must match exactly. Otherwise describe the
outcome and let the executor work from current source.

## Plan Header

```markdown
# [Feature Name] Implementation Plan

**Goal:** [observable outcome]

**Approach:** [concise architecture/data-flow summary]

**Spec:** [path to the existing approved design/requirements document, or "none"]

**Constraints and decisions:** [binding requirements; "none" if none]

**Execution recommendation:** Direct controller execution is the default. Use
delegation, a worktree, or `superpowers-lite:subagent-driven-development` only when the
risk/scale notes below justify them.

---
```

## Task Format

```markdown
### Task N: [Outcome]

**Goal:** [what this task leaves true]

**Files and symbols:**
- Modify: `path/to/file` — `RelevantSymbol`
- Test: `path/to/test`

**Acceptance criteria:**
- [ ] [observable behavior]

**Verification:** `[focused command or concrete manual/smoke procedure]`

**Risks/interfaces:** [only the load-bearing details]

**Depends on:** [task IDs or "none"]
```

Tasks should be independently understandable and as large as one coherent outcome.
They do not need to map one-to-one to commits. TDD cycles are execution technique,
not mandatory plan boilerplate. Do not add a commit step unless the user or project
workflow requires one.

Avoid empty placeholders such as "handle edge cases" or "add appropriate tests."
Name the behavior, failure mode, or evidence expected. It is acceptable for the
executor to discover ordinary implementation details from the codebase.

## Risk and Review Markers

Mark a task boundary `highRiskBoundary: true` only for:

- security or authentication/authorization;
- concurrency or synchronization;
- persistence, destructive data handling, or migrations;
- public API, wire protocol, or compatibility contracts;
- broad shared infrastructure;
- an explicit user requirement for independent review.

This marker requires one task-scoped independent review during delegated execution
before dependent work proceeds. Do not mark ordinary tasks merely because they are
delegated: they rely on implementer evidence plus controller acceptance and receive
no independent task review. Direct work has no independent review by default; Light
gets one final review only for substantive risk; Full gets one fresh whole-diff
review at the end.

For each task choose a `verificationScope`:

- `format` — prose/formatting/mechanical syntax-only changes;
- `focused` — affected unit/module checks;
- `dependent` — shared API or behavior affecting known consumers;
- `full` — cross-cutting, migration, security, concurrency, or integration boundary.

The scope describes evidence invalidated by that task; it is not a command to rerun
every test after every edit.

## Native Task Metadata

When a resumable or delegated workflow will consume the plan, create matching
native tasks (`TaskCreate`) and co-locate `<plan>.tasks.json`. Each task description carries the same
Goal / Files and symbols / Acceptance criteria / Verification / Risks/interfaces
content plus a final `json:metadata` fence:

```json
{
  "files": ["path/to/file"],
  "symbols": ["RelevantSymbol"],
  "verifyCommand": "focused command",
  "acceptanceCriteria": ["observable result"],
  "verificationScope": "focused",
  "highRiskBoundary": false,
  "modelTier": "mechanical"
}
```

`modelTier` is one of `mechanical`, `standard`, or `frontier`. Use task dependencies
only where execution order is real. Keep subjects compact. Native tasks are a
recovery/delegation aid, not a prerequisite to writing or directly executing a plan.

## User-Ordered Gates

Preserve explicit user sequencing such as "prove this on one target before all" or
a named acceptance/smoke gate. A bare verb such as "verify" or "check" is ordinary
verification, not a user gate.

For a real gate, add:

```json
{
  "userGate": true,
  "tags": ["user-gate"],
  "requiresUserSpecification": false,
  "gateScope": "one-then-all",
  "failurePolicy": "stop-plan"
}
```

Also put this banner below the task Goal in both the plan and persisted task:

> **USER-ORDERED GATE — NON-SKIPPABLE.** Close only after each acceptance criterion
> has fresh, captured evidence from the user-specified method.

Encode a concrete method the user already chose; do not reopen it without changed
facts. Set `requiresUserSpecification: true` only when no observable, capture method,
or pass/fail value can be inferred safely. `superpowers-lite:specifying-gates` collects
that missing information at execution time. Do not rely on hooks for enforcement.

## Self-Review

Before handoff, check once:

1. Every requirement and recorded user decision maps to a task or constraint.
2. Acceptance criteria and verification are operational, not adjectives.
3. File/symbol names and interfaces are internally consistent or explicitly marked
   for discovery.
4. Risk markers and verification scopes reflect blast radius.
5. The plan contains no accidental refactor, dependency, commit, worktree, review,
   or delegation mandate.

Fix issues inline. A separate plan reviewer is optional and reserved for plans whose
security, migration, public-contract, or architectural risk makes fresh eyes worth
the cost.

## Execution Handoff

Controller execution is the normal default in the current session unless the plan is long,
risky, parallelizable, explicitly delegated, or must resume elsewhere. Other valid
choices are:

- `superpowers-lite:subagent-driven-development` for routed, multi-agent execution of
  mostly independent tasks;
- `superpowers-lite:executing-plans` for a separate or resumable execution session.

Do not forbid direct implementation and do not force the user through a choice menu
when the requested execution mode is already clear. Worktree and review decisions
remain risk-calibrated at execution time.

### Separate-session handoff

When execution will resume in another session, give a paste-ready prompt containing
only the execution instructions. Fill in the real plan path and include the spec
path and author identity when known; omit unavailable fields instead of inventing
identifiers. Put commentary outside the code block:

```text
Use superpowers-lite:executing-plans to implement <plan path>.
Approved spec: <spec path, when present>.
Plan author: <known session/agent identity, when available>.
Read the plan and its referenced spec, preserve recorded decisions, and resume at the first incomplete outcome.
Consult the author for material intent ambiguity only if this host can reach that author; otherwise ask the user a focused question when necessary.
```

An author label is provenance, not proof of a reachable session. `SendMessage` reaches
only agents in the current session; it does not establish contact with independently
opened sessions. Check actual capabilities and author reachability before
consultation. Do not require a live author, force an execution
menu, or block routine work on author availability.
