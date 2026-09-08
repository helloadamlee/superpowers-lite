# Testing The Codex Plugin

The package is validated by focused Codex-native tests per platform and by a
complete native verifier per platform. Run the commands from this plugin
directory.

POSIX shell tests:

```bash
bash tests/codex-native/test-install-codex-agents.sh
bash tests/codex-native/test-routing-contract.sh
bash tests/codex-native/test-skill-routing-contract.sh
bash tests/codex-native/test-no-legacy-runtime.sh
sh scripts/verify-codex-plugin.sh
```

Windows PowerShell 5.1 and PowerShell 7 tests (same directory, no Bash, WSL, jq,
grep, find, Pester, or third-party PowerShell modules required):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\codex-native\test-install-codex-agents.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\codex-native\test-routing-contract.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\codex-native\test-skill-routing-contract.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\codex-native\test-no-legacy-runtime.ps1
.\scripts\verify-codex-plugin.ps1
```

Under PowerShell 7, `pwsh -NoProfile -File` may replace `powershell.exe` in each
command.

## What is validated

The installer tests use disposable target directories and prove exact, idempotent,
non-destructive role installation on both platforms. Routing tests prove the closed
tier-to-role map. Skill-contract tests prevent raw model aliases and require
explicit Codex roles plus platform-aware install and resolver instructions.
Runtime tests prove that non-Codex manifests, hooks, commands, and host files are
absent.

Each full verifier validates the manifest, runs every focused test for its runtime,
validates every skill and the plugin with the canonical Codex validators, and scans
shipped files for legacy host or model identifiers.

## Validator dependency

Both verifiers invoke the official Codex Python validators
(`quick_validate.py` and `validate_plugin.py`). Python 3 with PyYAML is required:

- POSIX: `python3` with PyYAML (`python3 -m pip install PyYAML`).
- Windows: the PowerShell verifier discovers `py -3`, then `python`, then
  `python3`; install PyYAML into that interpreter.

By default the verifiers locate the validators under `$CODEX_HOME/skills/.system`
(`%CODEX_HOME%\skills\.system` on Windows). Set `CODEX_VALIDATOR_ROOT` to point at
any checkout containing `skill-creator/scripts/quick_validate.py` and
`plugin-creator/scripts/validate_plugin.py`, such as a pinned `openai/codex`
checkout.

Continuous integration runs three independent jobs on every push: Linux with the
POSIX verifier, and Windows twice with the PowerShell verifier under Windows
PowerShell 5.1 (`shell: powershell`) and PowerShell 7 (`shell: pwsh`). See
`.github/workflows/verify.yml`.
