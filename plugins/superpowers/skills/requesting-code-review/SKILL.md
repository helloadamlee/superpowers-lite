---
name: requesting-code-review
description: Request an independent read-only review when change risk, a high-risk boundary, or an explicit user requirement makes fresh eyes valuable
---

# Requesting Code Review

Independent review is a risk control, not a ritual after every task. Spend it where a
fresh model can materially reduce uncertainty.

## Review Policy

| Lane or boundary | Independent review |
|---|---|
| Direct | None by default. Use controller self-review plus focused verification. |
| Light | One final review only when the change has substantive risk. |
| Full | One fresh whole-diff review after implementation and verification. |
| Explicitly marked high-risk task boundary | Required task-scoped review before dependent work continues. |
| User explicitly requires review | Required at the scope the user named. |

High-risk task boundaries are security/auth, concurrency, persistence or data
migration, public API or protocol contracts, broad shared infrastructure, or an
explicit user-required task review. Planning records these as
`highRiskBoundary: true`; the marker requires one task-scoped independent review.
Do not schedule per-task review for ordinary delegated feature slices.

Review can also be useful when stuck on a complex defect or before a dangerous
refactor. It is not warranted for formatting, comments, redundant punctuation,
generated output, or a mechanical change already covered by focused evidence.

## Host Capability Gate

Independent review requires routed mode from `skills/shared/codex-routing.md`.
Inspect the host's callable tool list first. If `spawn_agent` is absent, announce
"independent review unavailable" and either perform a clearly labeled controller
self-review when reduced assurance is acceptable, or stop when independent review
is explicitly required. Never describe controller self-review as independent.

When warranted, dispatch a fresh `superpowers_astra_reviewer` with `fork_turns: none`
and the template at [code-reviewer.md](code-reviewer.md). Never silently substitute a
generic, inherited-model, or write-capable agent.

## Review Package

Give the reviewer precise work-product context, not the controller's session history:

- requirements or plan;
- base and head SHAs;
- an explicit artifact from `scripts/review-package PLAN_FILE BASE HEAD`, which
  includes the committed range plus staged, unstaged, and untracked state even when
  `BASE == HEAD`;
- the verification already run and its results;
- known high-risk interfaces and compatibility constraints.

Do not dispatch an independent review with an empty committed diff while omitting
uncommitted work. Commit remains optional; the captured review artifact is required.

The reviewer remains read-only and reports Critical, Important, and Minor findings.
Each finding should name a `verificationScope`: `format`, `focused`, `dependent`, or
`full`.

## Acting on Findings

First verify that each finding applies in the current code and requirements. Then
classify the fix by blast radius, independently of how embarrassing or small the
finding looks:

- **Mechanical/trivial:** formatting, comment, punctuation, obvious import cleanup,
  or equivalent no-judgment edit. Fix inline, run formatter/compiler/static check as
  appropriate, and do not re-review.
- **Localized substantive:** fix the affected logic and run focused tests. Re-review
  only if the fix involves meaningful judgment or the original finding cannot be
  verified directly.
- **Shared contract:** run dependent tests and use a scoped re-review when the fix
  changes public/shared behavior.
- **Security, concurrency, persistence, migration, or cross-cutting:** run the full
  relevant verification and use a fresh scoped re-review.

Critical and valid Important findings must be resolved or explicitly surfaced before
integration. Minor findings do not automatically create a fix/re-review loop. New
findings in a scoped re-review count only when they are inside the fix diff and
Important or Critical; unrelated observations wait for the final review or are
reported without reopening the loop.

The full suite normally runs once at the final integration boundary. Run it earlier
again only when a broad fix invalidates that evidence.

## Avoid Review Inflation

- Do not request review solely because work is multi-file or delegated.
- Do not split spec and quality into separate reviewer passes when one scoped review
  can assess both.
- Do not re-review a mechanical correction.
- Do not rerun a broad suite when the fix invalidated only format or focused evidence.
- Do not supply a reviewer with prior reviewer opinions; fresh eyes need the work,
  requirements, and evidence.
