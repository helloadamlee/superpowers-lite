# Codex Routing Contract

Superpowers delegates through exact Codex custom-agent roles. Never pass legacy model
aliases or rely on an omitted role to inherit the coordinator's model.

| modelTier | agent_type | model | effort |
| --- | --- | --- | --- |
| mechanical | superpowers_luna_implementer | gpt-5.6-luna | medium |
| standard | superpowers_terra_implementer | gpt-6.1-sol | high |
| frontier | superpowers_astra_implementer | gpt-6-astra | high |
| review | superpowers_astra_reviewer | gpt-6-astra | high, read-only |

## Model selection and task direction

GPT-6.1 Sol is the standard implementation default; the existing
`superpowers_terra_implementer` role name remains stable for plans and resolvers.
Keep Luna for fully specified mechanical work and Astra for architectural judgment
and independent review. Preserve the configured effort when changing models;
raise it only for demonstrated reasoning difficulty, not simply because a model is
new. Treat this allocation as a starting policy: compare correctness, rework,
latency, and total task cost on representative tasks before changing another tier.
OpenAI describes Sol as near-Astra at lower cost, not equivalent on every task.
See the [Sol model documentation](https://developers.openai.com/api/docs/models/gpt-6.1-sol).

Give each agent the intended outcome, owned files, constraints, completion criteria,
and required verification. Let it choose routine implementation steps within that
contract. Load supporting references when the task needs them. Complete authorized
work and fix failures caused by the change before reporting; ask only when a missing
decision would materially change the result or exceed authorization. Run the checks
appropriate to the change and all required gates, then broaden verification only
for new failures, changes, or unresolved risk. These defaults follow OpenAI's
[model guidance](https://developers.openai.com/api/docs/guides/latest-model) and
[skill guidance](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).

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
