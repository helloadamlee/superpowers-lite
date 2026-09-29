# Changes from superpowers-codex

`superpowers-lite` adapts the upstream workflow for Codex with process scaled to
the consequences of the task. Clear requests proceed through implementation and
verification; design documents, delegation, and independent review are used where
they address a concrete risk.

## Direct, Light, and Full workflows

- **Direct:** clear, bounded, reversible work. Inspect the relevant context and
  implement with focused verification. No redundant scope confirmation or approval.
- **Light:** limited decisions and understood interfaces. Summarize scope,
  approach, acceptance criteria, and verification in chat, then implement under
  existing authorization. Persist a document or ask for approval only when the user
  requests it or an unresolved material decision requires it.
- **Full:** architectural, cross-cutting, long, or high-risk work. Develop and
  approve the design, persist it, and write an outcome-oriented implementation plan.
  Use isolation, delegation, and one final independent whole-diff review when their
  prerequisites are met.

Risk and uncertainty determine the lane; file count alone does not. A written plan
does not require delegating every task. The controller normally handles Direct and
Light work.

## Questions and alternatives

Batch independent questions into one round-trip. Ask a later question separately
only when its framing depends on an earlier answer. Honor decisions already made
by the user and resolve ordinary implementation choices from project conventions.

Compare approaches when there is a real design fork. A clear approach does not need
manufactured alternatives or another approval cycle.

## Proportional testing

Test-first development remains the default for reproducible bugs and nontrivial
behavior changes. Documentation, configuration, generated output, mechanical
edits, simple glue, and covered refactors use focused existing evidence appropriate
to the change. Add tests when they catch a durable regression risk.

If implementation precedes a needed test, backfill proof: write the test, confirm
it passes, deliberately break the relevant behavior, confirm the expected failure,
then restore and rerun. Mutation backfill is recovery evidence, not routine ceremony
after a successful test-first cycle.

Run the full suite at the integration boundary. Repeat or broaden evidence when a
later change invalidates it or a specific unresolved risk requires it.

## Review and fixes

Direct work has no default independent review. Light work gets a final review when
substantive risk warrants it. Full delegated work gets one fresh independent
whole-diff review. Per-task review is required only at an explicit
`highRiskBoundary: true` boundary before dependent work.

Fix mechanical findings inline with format or static evidence and no re-review.
Substantive fixes receive verification matching their impact and, when warranted,
one scoped re-review of the fix diff. There is one substantive fix wave per review;
surface unresolved load-bearing findings instead of repeating review/fix rounds or
silently escalating models.

## Codex routing

Delegation uses exact custom roles with fresh context. Mechanical work uses
GPT-5.6 Luna at medium effort; standard implementation uses GPT-6.1 Sol at high
effort through the stable `superpowers_terra_implementer` role; frontier
implementation and independent review use GPT-6 Astra at high effort.

Check host capability and installed roles before dispatch. If delegation is
unavailable, announce single-agent mode where the task permits it. If a required
role or model is unavailable, report the exact failure and request restoration, an
explicit tier change, or a stop. Never silently substitute a role or model.

Implementers and reviewers are leaf agents. The controller owns dispatch,
acceptance, integration, and any required independent review.

## Evidence and context hygiene

File-based briefs, reports, and review packages carry requirements and evidence
between sessions without copying accumulated controller history. Verification
claims need actual, applicable output, including failed or unavailable checks.
Review packages cover committed, staged, unstaged, and untracked work so a review
can inspect the real change even before a commit.

See the [plugin README](plugins/superpowers/README.md) for installation, model
policy, supported platforms, and reproducible developer checks.
