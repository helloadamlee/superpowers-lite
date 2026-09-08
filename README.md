# Superpowers Lite

A streamlined, Codex-native edition of Superpowers: structured planning,
test-driven development, systematic debugging, multi-agent execution, and verified
delivery without forcing heavyweight process onto small tasks.

## Highlights

- Direct, Light, and Full workflows scale process to the task.
- Deterministic custom-agent routing never silently substitutes models.
- GPT-6 Astra handles frontier implementation and independent review.
- GPT-5.6 Terra and Luna keep routine delegated work fast and economical.
- POSIX and Windows installers configure the same role policy.
- Plugin validation and routing contract tests run in CI.

| Tier | Role | Model | Use |
| --- | --- | --- | --- |
| Mechanical | `superpowers_luna_implementer` | `gpt-5.6-luna` | Small, fully specified work |
| Standard | `superpowers_terra_implementer` | `gpt-5.6-terra` | Integration and debugging |
| Frontier | `superpowers_astra_implementer` | `gpt-6-astra` | Broad judgment and architecture |
| Review | `superpowers_astra_reviewer` | `gpt-6-astra` | Fresh, read-only review |

## Install

```bash
git clone https://github.com/helloadamlee/superpowers-lite.git
cd superpowers-lite
codex plugin marketplace add "$PWD"
codex plugin add superpowers@superpowers-lite
cd plugins/superpowers
sh scripts/install-codex-agents.sh
sh scripts/install-codex-agents.sh --check
```

Start a new Codex task after installation so the custom roles are discovered.
Windows installation and model-policy customization are documented in the
[plugin README](plugins/superpowers/README.md).

## Verify

```bash
cd plugins/superpowers
sh scripts/verify-codex-plugin.sh
```

The verifier checks the plugin manifest, every skill, role installation, routing
contracts, and Codex-only runtime boundaries. GitHub Actions runs the equivalent
checks on Linux, Windows PowerShell 5.1, and PowerShell 7.

See [CHANGES.md](CHANGES.md) for the differences from the upstream workflow.

## License and provenance

MIT licensed. This project is a streamlined fork of
[`pcvelz/superpowers`](https://github.com/pcvelz/superpowers), which adapts
[`obra/superpowers`](https://github.com/obra/superpowers) for Codex. See
[NOTICE](NOTICE) and the retained [LICENSE](plugins/superpowers/LICENSE).
