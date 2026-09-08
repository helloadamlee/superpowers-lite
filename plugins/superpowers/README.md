# Superpowers Plugin

Superpowers is a Codex-native workflow plugin for structured design,
implementation planning, test-first development, systematic debugging, and
verified delivery. It routes delegated work through explicit Codex custom-agent
roles rather than inheriting an arbitrary session model.

## Requirements

- Codex with plugin support. Custom-agent support is required for routed delegation;
  direct workflows can run in explicit single-agent mode.
- Access to the configured GPT-6 Astra and GPT-5.6 model lanes, or a local edit to the role
  templates under `agents/` that matches your available models.

## Installation

Install this repository as a marketplace, then install the plugin:

```bash
codex plugin marketplace add /absolute/path/to/superpowers-lite
codex plugin add superpowers@superpowers-lite
```

Install the custom-agent role templates. Use the commands for your current
platform; no emulator is required on any platform.

POSIX (bash, zsh, or any POSIX shell):

```bash
cd /absolute/path/to/superpowers-lite/plugins/superpowers
sh scripts/install-codex-agents.sh
sh scripts/install-codex-agents.sh --check
```

Windows PowerShell 5.1 and PowerShell 7:

```powershell
Set-Location C:\absolute\path\to\superpowers-lite\plugins\superpowers
.\scripts\install-codex-agents.ps1
.\scripts\install-codex-agents.ps1 -Check
```

The POSIX installer writes to `CODEX_HOME/agents` when configured, otherwise
`~/.codex/agents`. The PowerShell installer prefers `CODEX_HOME\agents`, then
`$UserProfile\.codex\agents`. Installation only verifies role template files; it
does not prove that delegation works. The host capability gate below governs
whether `spawn_agent` delegation is available.

Start a new Codex task after installation so the custom roles are discovered.

## Routing

| Tier | Role | Default model | Effort | Use |
| --- | --- | --- | --- | --- |
| mechanical | `superpowers_luna_implementer` | `gpt-5.6-luna` | medium | Fully specified bounded work |
| standard | `superpowers_terra_implementer` | `gpt-5.6-terra` | high | Integration and debugging |
| frontier | `superpowers_astra_implementer` | `gpt-6-astra` | high | Broad judgment or architecture |
| review | `superpowers_astra_reviewer` | `gpt-6-astra` | high, read-only | Fresh diff review |

Plan tasks declare `modelTier`. The execution workflow resolves it to an exact
`agent_type`, passes a structured brief, and dispatches with `fork_turns: none`.
Implementers and reviewers are leaf agents: they never spawn helpers or their own
reviewers. Only the controller dispatches work.

Before dispatching, the workflow checks the current host's callable tools. It enters
routed mode only when `spawn_agent` and the exact role are exposed. If delegation is
unavailable, compatible workflows announce single-agent mode and report that no
independent subagent review occurred. A workflow stops instead when the user or task
explicitly requires subagents, parallel delegation, or independent review. This
capability check is the same in the Codex CLI and IDE integrations.

If a required role or model is unavailable, the workflow pauses. Restore access,
explicitly change the recorded task tier, or stop; it never silently substitutes a
model.

## Configure your model policy

The shipped roles are a reference policy. To use different model access or
reasoning-effort settings, edit the TOML files in `agents/` before running the
installer. The resolver intentionally maps tiers only to role names, so the
workflow remains stable while the role templates express your account's model
policy.

## Development checks

From this plugin directory, run the native full verifier for your platform:

```bash
sh scripts/verify-codex-plugin.sh
```

Windows PowerShell 5.1 and PowerShell 7:

```powershell
.\scripts\verify-codex-plugin.ps1
```

The verifier validates the manifest, skills, role installer, routing contract, and
absence of non-Codex runtime files. The Windows path needs Python 3 with PyYAML for
the canonical Codex validators; it does not require Bash, WSL, jq, grep, find,
Pester, or any third-party PowerShell module.

## License and provenance

Superpowers is MIT licensed. This lite distribution is a Codex-native adaptation of
[`obra/superpowers`](https://github.com/obra/superpowers), incorporating workflow
material from [`pcvelz/superpowers`](https://github.com/pcvelz/superpowers). It
retains the upstream license notice; see the repository-level `NOTICE` for the
scope of this adaptation.
