# Changes from superpowers-codex

`superpowers-lite` is a fork of `superpowers-codex` that removes process
overhead written to compensate for weaker models rationalizing their way out
of discipline. That overhead doesn't pay for itself against current frontier
models on small or medium tasks. Nothing about verification, review
independence, or context hygiene was loosened — those get more valuable as
models get more capable of writing plausible-sounding false claims, not less.

## 1. Brainstorming got a lane triage

`skills/brainstorming/SKILL.md` no longer runs the full
explore → questions → approaches → design doc → spec review → user-review →
writing-plans pipeline for every request regardless of size. It now triages
into three lanes before asking anything:

- **Direct** — single-file, reversible, no real ambiguity: implement after a
  one-line scope confirmation. No spec doc, no plan doc.
- **Light** — a few files or one subsystem: one combined spec+plan doc, one
  batched round of questions, one approval gate.
- **Full** — new subsystem or genuine architectural ambiguity: the original
  full process.

The old skill treated "this is too simple to need a design" as the anti-pattern
to guard against unconditionally. The anti-pattern is real, but the fix isn't
running the same four-gate process on a config change as on a new subsystem.

## 2. Clarifying questions are batched, not one-per-message

The original required exactly one question per chat message. Batched
multi-select questions (a single `AskUserQuestion` call carrying several
independent questions) resolve the same decisions in one round-trip. Split
into a second round only when a later question's framing genuinely depends
on an earlier answer.

## 3. "Propose 2-3 approaches" is conditional

Only proposed when there's a real fork — genuinely different architectures
with different trade-offs. When one approach is clearly correct, the skill
now says so and explains why, instead of manufacturing alternatives to
compare against.

## 4. Redundant DOT graphs removed

Six skill files carried Graphviz `digraph` blocks that restated the
surrounding prose almost verbatim — about 170 lines, several of them full
duplicates of an adjacent numbered list. These helped weaker models lock in
step ordering. They're gone; the same branching is stated once, in prose, in
`brainstorming`, `dispatching-parallel-agents`, `subagent-driven-development`,
and `systematic-debugging/{condition-based-waiting,root-cause-tracing}.md`.

## 5. TDD: mutation-check backfill instead of mandatory delete-and-restart

`skills/test-driven-development/SKILL.md`'s Iron Law previously required
deleting any code written before its test, no exceptions, even if the code
was correct. The lite version defaults to a cheaper proof: write the test,
confirm it passes, then deliberately break the implementation (comment out
the logic, invert a condition) and confirm the test now fails for the right
reason. That's the same guarantee test-first gives — the test provably
catches the bug — without discarding working code. Full delete-and-restart
is still there for code that isn't trustworthy (unclear intent, written
under enough pressure that correctness is itself in doubt, or the mutation
check fails to catch the deliberate break).

Also: refactoring — behavior-preserving change under tests that already
cover it — was pulled out of the "always TDD" list. Red-green-refactor
doesn't apply to a change with no new behavior; the tests it runs against
already exist. Refactoring code with no covering test is a bug-fix/feature
situation (add the missing test first), not a refactor.

## 6. Fix-loop escalation moved to the first failed review

`skills/subagent-driven-development/SKILL.md`'s fix loop previously resumed
the same implementer for three rounds before escalating to a fresh
implementer on a more capable model in rounds 4-5. The lite version escalates
after round 1: round 1 resumes the original implementer with the findings,
and round 2 (if needed) goes straight to a fresh implementer on a more
capable model. A same-model retry after one failed review tends to reproduce
the same blind spot; there's little reason to pay for two more attempts
before trying a different model.

## 7. Fix-loop cap reduced from 5 rounds to 2

A task that still fails review after round 2 (one same-model retry, one
capability escalation) is treated as a plan or spec problem, not an
implementer problem — the breaker trips and findings get adjudicated
(parked with a ruling, or the task is marked BLOCKED for load-bearing
issues) rather than burning three more rounds. This lowers the worst-case
cost per task from up to 5 fix-dispatch + re-review pairs to 2.

## What stayed the same, deliberately

- File-based brief/report/review-package handoffs between controller and
  subagents — context hygiene matters more as tasks get longer, not less.
- `verification-before-completion`'s evidence-before-claims gate — stronger
  models produce more plausible false claims, so this check doesn't decay.
- The rule against pre-judging reviewer findings ("don't tell a reviewer what
  not to flag").
- The final whole-branch review as a separate pass from per-task review —
  integration defects only surface there.
