# Codex Routing Contract

Superpowers delegates through exact Codex custom-agent roles. Never pass legacy model
aliases or rely on an omitted role to inherit the coordinator's model.

| modelTier | agent_type | model | effort |
| --- | --- | --- | --- |
| mechanical | superpowers_luna_implementer | gpt-5.6-luna | medium |
| standard | superpowers_terra_implementer | gpt-5.6-terra | high |
| frontier | superpowers_astra_implementer | gpt-6-astra | high |
| review | superpowers_astra_reviewer | gpt-6-astra | high, read-only |

## Host Capability Gate

Before any delegation workflow, inspect the host's callable tool list. Select a
mode from capabilities, not from whether the host is the Codex CLI or an IDE:

- **Routed mode:** `spawn_agent` is callable and Codex exposes the exact custom
  `agent_type` required by the task. Continue with the routing checks below.
- **Single-agent mode:** `spawn_agent` is not callable. Announce that custom-agent
  delegation is unavailable, perform implementation and verification directly in
  the controller, and report that no independent subagent review occurred. If the
  user or task explicitly requires subagents, parallel delegation, or independent
  review, stop and explain the missing host capability instead.

Do not infer runtime support from installed role files, the plugin manifest, or the
host name. Do not probe by attempting to invoke a tool that is absent from the
callable tool list. In single-agent mode, the controller must not claim that routed
implementation, parallel agents, or independent review occurred.

## Platform Commands

Select install, check, and resolver commands by current platform. The table names
the native entry points; no emulator is required on any platform.

Resolve every `scripts/...` path in Superpowers instructions against the installed
Superpowers plugin root, not the user's project directory. Derive that root from the
loaded skill's path and invoke the resulting absolute path while keeping the user's
project as the working directory.

| Host | Install/check | Resolve tier |
| --- | --- | --- |
| POSIX shell | `sh scripts/install-codex-agents.sh [--check]` | `sh scripts/resolve-codex-role.sh <tier>` |
| Windows PowerShell 5.1 or PowerShell 7 | `.\scripts\install-codex-agents.ps1 [-Check]` | `.\scripts\resolve-codex-role.ps1 <tier>` |

Passing an installer or check command for the current platform only proves role
template files exist. It does not prove `spawn_agent` is callable; the Host
Capability Gate above still governs delegation.

In routed mode, run the install-check command for the current platform and verify
that Codex exposes the exact `agent_type`. Build a structured brief containing the
task goal, owned files, acceptance criteria, verification command, constraints, and
dependencies. Use `spawn_agent` with `fork_turns: none` and the role selected by the
tier resolver for the current platform.

A worker report is evidence, not automatic acceptance. The coordinator inspects the
actual diff and report, checks every acceptance criterion, and reruns only evidence
that is missing, doubtful, or invalidated by later changes. Do not repeat all worker
verification by default.

Ordinary delegated tasks complete from implementer evidence plus controller
acceptance; they do not receive independent task review. A task explicitly marked
`highRiskBoundary: true` requires one fresh `superpowers_astra_reviewer` before
dependent work proceeds. Full-lane work receives one final fresh whole-diff review.
Each reviewer returns exactly one top-level verdict — `ship`, `fix-first`, or
`rethink` — and must remain read-only.

If `spawn_agent` is callable but a role is missing, stale, unavailable, or its model
cannot launch, stop delegation and tell the user the required tier, role, model,
effort, observed failure, and the install/check command. Offer only these decisions:

1. Restore the exact role or model access and retry.
2. Explicitly change the task's modelTier, record the change, and retry.
3. Stop the task.

Never silently substitute another role, model, or reasoning level.
