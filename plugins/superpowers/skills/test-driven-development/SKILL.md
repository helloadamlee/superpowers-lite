---
name: test-driven-development
description: Use test-first development for bugs and nontrivial behavior; choose proportional evidence for mechanical, configuration, documentation, generated, simple UI, and glue changes
---

# Proportional Test-Driven Development

Tests should prove behavior and prevent plausible regressions. The amount and order
of evidence should match the kind of change.

## Choose the Evidence Path

### Test-first is the default for

- bug fixes: reproduce the defect with a failing regression test;
- nontrivial new behavior or behavior changes;
- error handling, boundary conditions, state transitions, algorithms, and contracts;
- logic whose intended result can be expressed before implementation.

For these changes:

1. Write the smallest test that states the behavior.
2. Run it and confirm it fails for the expected missing behavior, not a typo or
   environment problem.
3. Implement the minimum coherent fix.
4. Run the focused test and relevant neighboring tests.
5. Optionally clean up if the result is clearer or safer; keep evidence green.

Test behavior, not every new function or method. Helpers, accessors, and forwarding
code earn separate tests only when they expose behavior not already covered.

### Existing focused evidence is usually enough for

- pure configuration and declarative metadata;
- documentation and instruction text;
- generated code or generated assets;
- formatting, renames, imports, and other mechanical transformations;
- simple UI wiring or glue code with no new decision logic;
- pure refactors already protected by meaningful tests.

Use the cheapest evidence that can actually catch a mistake: parser/validator,
formatter, compiler/type checker, focused existing test, snapshot, smoke run, or a
documented manual interaction. Add an automated test only when the change introduces
a durable behavior or regression risk the existing evidence cannot detect.

Do not ask for permission merely to use this proportional path. Explain the chosen
evidence when it is not obvious.

## A Good RED

A useful failing test:

- names one externally meaningful behavior;
- fails because the behavior is absent or wrong;
- derives the expected result independently of the implementation;
- uses real collaborators where practical and mocks only a true boundary;
- would still matter after internal refactoring.

When writing or changing tests, read [writing-good-tests.md](writing-good-tests.md).
Avoid change-detector tests that grep source wording, assert removed symbols remain
absent, or duplicate framework behavior without testing your contract.

## Code Written Before the Test

Do not automatically delete correct work. Backfill proof when implementation
preceded the test or when a new test's sensitivity is uncertain:

1. Write the focused test and confirm it passes against the implementation.
2. Deliberately mutate the relevant behavior (invert the condition, remove the core
   call, or return a wrong value).
3. Confirm the test fails for the intended reason.
4. Revert the mutation and rerun the focused evidence.

Mutation backfill is not routine ceremony after a normal test-first cycle. Use it
only for code-before-test recovery or genuine uncertainty that the test can detect
the defect. If the test survives the mutation, improve the test before claiming
coverage.

## Bug Fixes

Every reproducible bug fix should leave a regression test unless automation is
impractical or the defect exists only in configuration, documentation, generated
output, or an external/manual environment. In those exceptional cases, capture the
focused validator, smoke, or manual reproduction-and-fix evidence instead.

The regression test should fail on the defect and pass on the fix. It need not create
a unit test for every helper touched while fixing it.

## Refactoring

Refactoring is optional cleanup after correctness, not an automatic phase. Refactor
when it removes meaningful duplication, clarifies a risky boundary, or is needed to
make the requested behavior safe. Do not widen scope just because tests are green.

For pure refactors, keep existing behavior evidence green. Add characterization
tests first only where the behavior being preserved lacks credible coverage.

## Verification Scope

- **Format:** formatter/parser/static validation for prose or mechanical changes.
- **Focused:** changed behavior plus its module or direct consumers.
- **Dependent:** public/shared contract and known downstream consumers.
- **Full:** final integration boundary, or a broad security, concurrency,
  persistence, migration, or cross-cutting change.

Run the full suite once at the final integration boundary unless a broad later fix
invalidates that evidence. A punctuation or formatting correction does not invalidate
1,500 behavioral tests.

## Completion Check

Before claiming completion, be able to state:

- what behavior or artifact changed;
- what evidence could have caught an error in that change;
- the fresh command or manual procedure and its result;
- why the chosen scope is proportional to blast radius;
- any meaningful gap in automated coverage.

This skill never weakens `superpowers:verification-before-completion`: claims still
require fresh evidence. Proportional means targeted evidence, not assumed evidence.
