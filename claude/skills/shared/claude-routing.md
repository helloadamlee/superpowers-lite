# Claude Code Routing Contract

Superpowers Lite delegates through four named subagents. The controller picks a lane
from the task's `modelTier` and dispatches the matching agent with the `Agent` tool.
Each agent file pins its own model and effort, so the policy lives in one place
(`agents/*.md`) and plans only ever name a tier.

| modelTier | subagent_type | model alias | effort | Fallback |
| --- | --- | --- | --- | --- |
| mechanical | `superpowers-lite:mechanical-implementer` | `haiku` (Haiku 5.5) | medium | none |
| standard | `superpowers-lite:standard-implementer` | `sonnet` (Sonnet 5.5) | high | none |
| frontier | `superpowers-lite:frontier-implementer` | `fable` (Fable 5.1) | high | `opus` (Opus 5.5) |
| review | `superpowers-lite:reviewer` | `fable` (Fable 5.1) | high, read-only | `opus` (Opus 5.5) |

Aliases resolve to the current model for the user's provider, so the same plugin works
on the Anthropic API, Bedrock, and Vertex. The model names in the table are what the
aliases resolved to when this was written (Claude Code 2.1.293); an older Claude Code
or a provider pinned to older versions may resolve `haiku` to an earlier Haiku. To pin
an exact version, edit `model:` in the agent file to a full model ID.

## Choosing a lane

Keep routine work in the controller. Delegate when isolation, parallelism, or a fresh
perspective earns its cost.

- **mechanical:** the brief is precise enough that the work is typing, not deciding.
- **standard:** integration, debugging, and multi-file changes inside a settled design.
- **frontier:** broad judgment, ambiguous integration, or architecture-sensitive work.
- **review:** independent, read-only review of a captured diff.

Treat the allocation as a starting policy. If a lane produces rework, compare
correctness, rework, latency, and cost on representative tasks before moving a tier.
Keep a role's configured effort when changing models; raise it only for demonstrated
reasoning difficulty.

## Task direction

Give each agent the outcome, owned files, constraints, completion criteria, and the
verification to run, and let it choose the routine steps. Point it at files for long
material (task brief, report file, review package) instead of pasting the material
through your own context. Subagents start with fresh context and do not inherit your
conversation, so the brief has to carry everything the agent needs.

Complete authorized work and fix failures the change caused before reporting. Ask only
when a missing decision would materially change the result or exceed authorization.

## Delegation capability

Before delegating, check that the `Agent` tool is available to you and that the
`superpowers-lite:*` agent types are listed in its description.

- **Routed mode:** `Agent` is available and the needed agent type is listed.
- **Single-agent mode:** `Agent` is unavailable (for example, you are yourself a
  subagent). Say that delegation is unavailable, do the work directly, and report that
  no independent review took place. If the user or plan explicitly requires subagents or
  independent review, stop and explain what is missing.

Never describe controller self-review as independent review, and never describe
sequential controller work as parallel agents.

## Dispatching

Use the `Agent` tool with `subagent_type` set to the lane's agent, a short
`description`, and a structured `prompt` (goal, owned files, acceptance criteria,
verification command, constraints, dependencies). Do not pass `model` for a normal
dispatch: the agent file supplies it.

Implementers and reviewers are leaf agents. Their agent files remove the `Agent` tool,
so only the controller dispatches.

A worker report is evidence, not acceptance. Inspect the actual diff and report, check
each acceptance criterion, and rerun only evidence that is missing, doubtful, or
invalidated by a later change.

Ordinary delegated tasks complete from implementer evidence plus controller
acceptance. A task marked `highRiskBoundary: true` gets one fresh `reviewer` before
dependent work proceeds, and full-lane work gets one final whole-diff review. Each
review returns exactly one verdict: `ship`, `fix-first`, or `rethink`.

## Fable fallback

Fable 5.1 is the preferred model for the frontier and review lanes. It may be
unavailable to a user (no usage credits or entitlement for it, or not enabled for their
provider). Only those two lanes have a fallback, and it is explicit rather than silent.

1. Dispatch the lane normally.
2. If the dispatch fails before the agent does any work, with an error that names the
   model, access, credits, or availability, treat it as a model-access failure. A
   transient overload or rate limit gets one plain retry first. A failure inside the
   task is a task failure, not a model failure.
3. Tell the user once: the lane, `fable` unavailable, observed error, and that you are
   using `opus`. Then re-dispatch the same agent with the `Agent` tool's `model`
   parameter set to `opus`. The parameter accepts only the aliases `sonnet`, `opus`,
   `haiku`, and `fable`, and it takes precedence over the agent file. The role's effort
   stays the same.
4. Record `model-fallback: <lane> fable -> opus (<reason>)` in the SDD ledger or final
   report, and include it in the review package summary so reviewers and the user can see
   which model produced the work.
5. For the rest of the session, send frontier and review dispatches straight to `opus`
   and mention that restoring Fable access (or editing the agent files) returns the lanes
   to the preferred model.
6. If `opus` also fails with a model-access error, stop delegation. Report the lane,
   both models, and the errors, and offer: restore access and retry, explicitly change the
   task's tier and record it, or stop.

The mechanical and standard lanes have no automatic fallback. If their model is
unavailable, stop and offer the same three choices rather than moving the task to another
model on your own.

A refusal (`stop_reason: refusal` from a safety classifier) is not a model-access
failure and never triggers the fallback. Report it as a refusal with its category and
rephrase or rescope the brief; Haiku 5.5 in particular has no server-side fallback for it.

Do not use the fallback to hide a different problem: a missing agent type, a malformed
brief, or a task failure is reported as what it is.
