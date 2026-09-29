# Superpowers Plugin

Superpowers is a Codex-native workflow plugin for structured design,
implementation planning, test-first development, systematic debugging, and
verified delivery. It routes delegated work through explicit Codex custom-agent
roles rather than inheriting an arbitrary session model.

## Requirements

- Supported platforms: Linux and Windows with PowerShell 7. The POSIX scripts
  remain available for other POSIX environments, but CI covers Linux only.
- Codex with plugin support. Custom-agent support is required for routed delegation;
  direct workflows can run in explicit single-agent mode.
- Access to the configured GPT-6 Astra, GPT-6.1 Sol, and GPT-5.6 Luna model lanes,
  or a local edit to the role templates under `agents/` that matches your available models.

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

Windows PowerShell 7:

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

## Upgrade existing roles

The installer refuses to overwrite a role that differs from the shipped template,
including an unchanged role from an older release. For 6.4.1, the standard role
changes from Terra to Sol while keeping the `superpowers_terra_implementer` name.

1. Find your installed roles in `CODEX_HOME/agents` if `CODEX_HOME` is set,
   otherwise `~/.codex/agents` on Linux or `$env:USERPROFILE\.codex\agents` on Windows.
   If you installed with a custom target directory, use that directory.
2. Back up only these four Superpowers files to a separate directory:
   `superpowers-luna-implementer.toml`, `superpowers-terra-implementer.toml`,
   `superpowers-astra-implementer.toml`, and `superpowers-astra-reviewer.toml`.
3. Compare the backup with the new `agents/` templates. Review any local
   customizations and apply the settings you want to retain to the templates.
4. Move only those four installed files aside, retaining the backup. Leave other
   custom roles in place; never delete the entire agents directory.
5. From the plugin directory, rerun installation and its check:

Linux / POSIX:

```bash
sh scripts/install-codex-agents.sh
sh scripts/install-codex-agents.sh --check
```

Windows PowerShell 7:

```powershell
.\scripts\install-codex-agents.ps1
.\scripts\install-codex-agents.ps1 -Check
```

For a custom destination, pass `--target-dir /path/to/agents` or
`-TargetDir C:\path\to\agents` to both commands. Start a new Codex task afterward.

## Routing

| Tier | Role | Default model | Effort | Use |
| --- | --- | --- | --- | --- |
| mechanical | `superpowers_luna_implementer` | `gpt-5.6-luna` | medium | Fully specified bounded work |
| standard | `superpowers_terra_implementer` | `gpt-6.1-sol` | high | Integration and debugging |
| frontier | `superpowers_astra_implementer` | `gpt-6-astra` | high | Broad judgment or architecture |
| review | `superpowers_astra_reviewer` | `gpt-6-astra` | high, read-only | Fresh diff review |

The controller handles routine work directly. Delegated mechanical work needs a
precise brief; standard work needs integration and debugging judgment; frontier
work needs broader architectural judgment. Independent review uses a fresh Astra
context. Role names stay stable as the template model policy evolves.

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

The verifier uses canonical Codex validators from `CODEX_VALIDATOR_ROOT`, falling
back to `CODEX_HOME/skills/.system` (or `~/.codex/skills/.system`). A Codex installation
may not include both validators. For reproducible local checks, use the same pinned
Codex checkout as CI: revision `c1f1467f3028bd433c8f2063ecc28dd5be206df6`, with the
validator root at `codex-rs/skills/src/assets/samples`.

Linux needs Git, Python 3 with PyYAML, jq, ripgrep, Bash, and sh. Prepare a separate
validator checkout, then run the verifier from this plugin directory:

```bash
git clone --filter=blob:none --no-checkout https://github.com/openai/codex.git /absolute/path/to/codex-validators
git -C /absolute/path/to/codex-validators sparse-checkout set --no-cone codex-rs/skills/src/assets/samples
git -C /absolute/path/to/codex-validators checkout c1f1467f3028bd433c8f2063ecc28dd5be206df6
python3 -m pip install PyYAML
export CODEX_VALIDATOR_ROOT=/absolute/path/to/codex-validators/codex-rs/skills/src/assets/samples
cd /absolute/path/to/superpowers-lite/plugins/superpowers
sh scripts/verify-codex-plugin.sh
```

Windows PowerShell 7 needs Git and Python 3 with PyYAML:

```powershell
git clone --filter=blob:none --no-checkout https://github.com/openai/codex.git C:\absolute\path\to\codex-validators
git -C C:\absolute\path\to\codex-validators sparse-checkout set --no-cone codex-rs/skills/src/assets/samples
git -C C:\absolute\path\to\codex-validators checkout c1f1467f3028bd433c8f2063ecc28dd5be206df6
py -3 -m pip install PyYAML
$env:CODEX_VALIDATOR_ROOT = 'C:\absolute\path\to\codex-validators\codex-rs\skills\src\assets\samples'
Set-Location C:\absolute\path\to\superpowers-lite\plugins\superpowers
.\scripts\verify-codex-plugin.ps1
```

The verifier validates the manifest, skills, role installer, routing contract, and
absence of non-Codex runtime files. CI provisions the pinned validators automatically.
The Windows verifier does not require Bash, WSL, jq, grep, find, Pester, or any
third-party PowerShell module. Windows PowerShell 5.1 is outside this release's
support and CI matrix; the existing `.ps1` implementation is retained.

## License and provenance

Superpowers is MIT licensed. This lite distribution is a Codex-native adaptation of
[`obra/superpowers`](https://github.com/obra/superpowers), incorporating workflow
material from [`pcvelz/superpowers`](https://github.com/pcvelz/superpowers). It
retains the upstream license notice; see the repository-level `NOTICE` for the
scope of this adaptation.
