---
name: using-superpowers
description: Establish how Codex discovers and applies Superpowers skills before acting
---

# Using Superpowers

Before taking action, identify any applicable skill and load its complete SKILL.md.
Process skills such as brainstorming, debugging, and test-driven-development come
before implementation skills. User instructions take precedence over skills.

Calibrate process to the work instead of treating every multi-step request as a
project:

- **Direct:** clear, bounded, reversible work. The controller implements directly
  with focused verification. Do not require a redundant design approval, plan,
  worktree, delegation, or independent review.
- **Light:** a few files or one subsystem with limited ambiguity. Agree on a concise
  in-chat scope and plan once, then the controller normally implements it. Persist a
  plan, delegate, isolate, or request review only when a concrete risk justifies it.
- **Full:** complex, long, architectural, cross-cutting, or high-risk work. Use a
  persisted design and outcome-oriented plan; use worktrees, delegation, and one
  final independent whole-diff review when their prerequisites are met.

Escalate a lane when discovery reveals more risk. A checklist is tracked only when
it materially helps execution or recovery; loading a skill does not itself require
creating tracker tasks.

Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` for
genuinely complex, risky, long, parallel, or explicitly delegated execution. A
written plan never forbids capable controller execution.

## Codex Tool Mapping

- Skill invocation -> load the matching Codex skill natively.
- Task tracking -> Codex task tracker and update_plan.
- Delegation -> apply the host capability gate, then use spawn_agent with an exact
  role from skills/shared/codex-routing.md only in routed mode.
- Waiting -> wait_agent.
- File operations -> native Codex file and shell tools.

Before delegation, inspect the host's callable tool list and select routed or
single-agent mode as defined in the shared contract. In routed mode, run the
install-check command for the current platform (scripts/install-codex-agents.sh
--check on POSIX, .\scripts\install-codex-agents.ps1 -Check on Windows) and resolve
the task's modelTier with the platform resolver (scripts/resolve-codex-role.sh on
POSIX, .\scripts\resolve-codex-role.ps1 on Windows). Use fork_turns: none. If the
role or model is unavailable, pause for the explicit restore, tier-change, or stop
decision; never silently substitute.
