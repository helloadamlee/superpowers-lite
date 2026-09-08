---
name: codex-agent-routing
description: Install and verify Superpowers' Codex custom-agent routing roles
---

# Codex Agent Routing

Superpowers is Codex-only. Install the exact role templates before starting a new
task, using the commands for the current platform:

    sh scripts/install-codex-agents.sh [--check]

```powershell
.\scripts\install-codex-agents.ps1 [-Check]
```

The POSIX installer writes to CODEX_HOME/agents when CODEX_HOME is configured,
otherwise HOME/.codex/agents. The PowerShell installer prefers CODEX_HOME\agents
and otherwise uses USERPROFILE\.codex\agents. Start a new Codex task after
installation so native role discovery sees the templates.

Installation verifies role files only; it does not prove `spawn_agent` is callable.
The Host Capability Gate below governs delegation.

## Host Capability Gate

Installation verifies role files, not delegation support. Before dispatching,
inspect the host's callable tool list. Routed mode is available only when
`spawn_agent` is callable and the exact custom role is exposed. If `spawn_agent` is
absent, follow the shared routing contract's single-agent mode or stop when the
request explicitly requires subagents or independent review. Do not infer support
from whether Codex is running in the CLI or an IDE.

Routing is deterministic:

- mechanical -> superpowers_luna_implementer -> gpt-5.6-luna / medium
- standard -> superpowers_terra_implementer -> gpt-5.6-terra / high
- frontier -> superpowers_astra_implementer -> gpt-6-astra / high
- review -> superpowers_astra_reviewer -> gpt-6-astra / high / read-only

If the installer check fails, a role is not exposed, or its model cannot launch, pause
and tell the user the required role, model, effort, observed failure, and the exact
install/check command. Offer only these choices:

1. Restore access to the exact role/model and retry.
2. Explicitly change the task tier, record the change in metadata, and retry.
3. Stop the task.

Never silently select another role, model, or reasoning level.
