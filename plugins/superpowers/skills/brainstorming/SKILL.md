---
name: brainstorming
description: Use before creative or behavior-changing work when user intent, requirements, or design choices need exploration; scale the ceremony to Direct, Light, or Full risk
---

# Brainstorming Ideas Into Designs

Understand the request well enough to act without inventing requirements. Scale the
conversation to the cost of a wrong assumption.

Do not use brainstorming as a compulsory pause when the user has already supplied a
clear, bounded request. User instructions and existing project constraints are valid
decisions; do not ask the user to approve them again.

## Lane Triage

Choose a lane from the evidence you have. State it only when doing so helps the user
understand a non-obvious amount of ceremony.

| Lane | When | Workflow |
|---|---|---|
| **Direct** | One clear concern; reversible; no meaningful design fork | Inspect enough context, resolve genuine ambiguity if any, then implement directly. No redundant approval, spec, plan, task checklist, or approaches list. |
| **Light** | A few files or one subsystem; limited decisions; modest blast radius | Summarize scope, approach, acceptance criteria, and verification in chat. Batch any related questions. Get one approval, then normally implement in the controller. No mandatory document, commit, task tracker, or separate spec review. |
| **Full** | New subsystem, architectural fork, cross-cutting behavior, long effort, or expensive risk | Explore, compare real alternatives, present the design, persist the approved design, then invoke `superpowers:writing-plans`. |

Default to the least ceremony that safely resolves uncertainty. Escalate when
exploration uncovers wider impact; do not preserve a lighter lane after its
assumptions stop being true.

## Direct

1. Inspect the relevant project context.
2. If the request is unambiguous, proceed. If one missing decision would materially
   change the result, ask only for that decision.
3. Implement with the applicable implementation and verification skills.

The user's clear request is authorization to perform the requested work. Do not ask
"does this plan look right?" after merely restating it.

## Light

1. Inspect the relevant files, conventions, and constraints.
2. Batch independent questions into one round-trip. Split a later question only when
   its framing genuinely depends on an earlier answer.
3. If there is a real design fork, present the viable options and lead with a
   recommendation. Do not manufacture alternatives.
4. Give a concise in-chat brief covering:
   - scope and exclusions;
   - chosen approach and important interfaces;
   - acceptance criteria;
   - verification appropriate to the change.
5. Ask for one approval of that brief, incorporate requested changes, then implement.

Persist a Light brief only when the user asks, another session must consume it, or
the decisions are important enough to outlive the conversation. If persisted, an
inline self-check is enough; neither a commit nor a separate document-review agent is
required.

## Full

Track the Full workflow when recovery across a long session would benefit from it:

1. Explore project context and identify constraints.
2. Decompose independent subsystems before refining details.
3. Batch clarifying questions where possible.
4. Compare 2-3 approaches only for genuine architectural forks.
5. Present the design in sections scaled to complexity and get approval.
6. Save the approved design to
   `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` unless the user specifies a
   location.
7. Self-check it for omissions, contradictions, ambiguity, and accidental scope.
   Fix issues inline; do not create a review loop for the document.
8. Invoke `superpowers:writing-plans`.

Commit the design only when the repository workflow or user requests it. Writing a
document does not imply authorization to create a commit.

## Design Guidance

- Understand purpose, constraints, success criteria, and failure behavior.
- Follow existing project patterns. Include targeted cleanup only when it directly
  serves the requested change.
- Prefer small units with clear responsibilities and interfaces, but do not turn a
  feature request into an unrelated refactor.
- Cover architecture, data flow, error handling, compatibility, and testing only to
  the depth warranted by the lane.
- Record decisions the user already made. Do not reopen them without changed facts.

## Visual Companion

Offer a visual companion only when a concrete question would be materially clearer
as a mockup, wireframe, layout comparison, or architecture diagram. Make the offer
just in time and wait for acceptance before opening it. Textual requirements,
tradeoffs, and scope decisions stay in the conversation.

Even after acceptance, decide per question whether a visual adds value. Concise text
or a terminal-native diagram is preferable when it communicates the answer clearly.

## Transition

- Direct -> controller implementation.
- Light -> controller implementation by default; delegation or a persisted plan only
  when risk, scale, parallelism, or the user calls for it.
- Full -> `superpowers:writing-plans`.

Do not insert another approval or documentation cycle between an approved lane and
its transition unless new information creates a real decision.
