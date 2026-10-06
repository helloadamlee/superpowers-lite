---
name: using-superpowers
description: Use at the start of any task to decide which Superpowers skills apply and how much process the work needs (Direct, Light, or Full)
---

# Using Superpowers

Before acting, check whether a skill covers the task and load it with the `Skill` tool.
Load supporting references only when the workflow needs them. Process skills such as
brainstorming, debugging, and test-driven-development come before implementation skills.
User instructions take precedence over skills.

Calibrate process to the work instead of treating every multi-step request as a
project:

- **Direct:** clear, bounded, reversible work. Implement it yourself with focused
  verification. A redundant design approval, plan, worktree, delegation, or independent
  review adds cost without reducing risk.
- **Light:** bounded impact with limited ambiguity. Give a concise in-chat scope and
  plan, honoring authorization already present in the request. Ask only about material
  unresolved decisions, then implement it yourself. Persist a plan, delegate, isolate, or
  request review only when a concrete risk justifies it.
- **Full:** complex, long, architectural, cross-cutting, or high-risk work. Use a
  persisted design and outcome-oriented plan, and use worktrees, delegation, and one
  final independent whole-diff review when their prerequisites are met.

Escalate a lane when discovery reveals more risk. Track a checklist with `TaskCreate`
and `TaskUpdate` only when it helps execution or recovery; loading a skill does not
itself call for tasks.

Use `superpowers-lite:subagent-driven-development` or
`superpowers-lite:executing-plans` for complex, risky, long, parallel, or explicitly
delegated execution. A written plan never rules out executing it yourself.

## Follow-through

Define completion by the requested outcome and the evidence it needs. Carry authorized
work through implementation, verification, and fixes for failures the change caused.
Resolve routine choices from project conventions; ask a focused question (batch related
questions into one `AskUserQuestion` call) when the answer would change the outcome,
scope, or authority. Before asking for approval of a later action, prepare whatever
concrete result you can already produce.

If a skill calls for a pause, name the skill and quote the instruction that applies.

## Tools

| Need | Claude Code tool |
| --- | --- |
| Load a skill | `Skill` |
| Track tasks | `TaskCreate`, `TaskUpdate`, `TaskList` |
| Ask the user | `AskUserQuestion` |
| Delegate | `Agent` with a `superpowers-lite:*` subagent type |
| Inspect and edit files | `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Bash` |

## Delegation

Delegation follows [the routing contract](../shared/claude-routing.md). In short: check
that `Agent` is available, resolve the task's `modelTier` to its agent, and dispatch
with a self-contained brief. Task-direction guidance for briefs is in the same
document. If an agent's model is unavailable, follow its fallback rules rather than
swapping models on your own.
