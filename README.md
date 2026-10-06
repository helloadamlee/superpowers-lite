# Superpowers Lite

A streamlined, Codex-native edition of Superpowers: structured planning,
test-driven development, systematic debugging, multi-agent execution, and verified
delivery without forcing heavyweight process onto small tasks.

> Using Claude Code instead of Codex? See the [Claude Code edition](claude/README.md).

## Highlights

- Direct, Light, and Full workflows scale process to the task.
- Deterministic custom-agent routing never silently substitutes models.
- Plans preserve approved spec references and provide copyable Codex handoffs.
- Batch reviews check requested changes and surface missing verification evidence.
- GPT-6 Astra handles frontier implementation and independent review.
- GPT-6.1 Sol handles standard implementation; GPT-5.6 Luna handles mechanical work.
- Linux and Windows PowerShell 7 installers configure the same role policy.
- Plugin validation and routing contract tests run in CI.

| Tier | Role | Model | Effort | Use |
| --- | --- | --- | --- | --- |
| Mechanical | `superpowers_luna_implementer` | `gpt-5.6-luna` | medium | Small, fully specified work |
| Standard | `superpowers_terra_implementer` | `gpt-6.1-sol` | high | Integration and debugging |
| Frontier | `superpowers_astra_implementer` | `gpt-6-astra` | high | Broad judgment and architecture |
| Review | `superpowers_astra_reviewer` | `gpt-6-astra` | high | Fresh, read-only review |

Choose the lane by the judgment the task needs. Keep routine work in the controller,
use Luna for precise mechanical briefs, Sol for standard implementation, and Astra
for frontier work and independent review. The stable `superpowers_terra_implementer`
role name now routes to Sol.

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
Existing users should follow its [role upgrade steps](plugins/superpowers/README.md#upgrade-existing-roles)
before reinstalling changed templates.

## Verify

```bash
cd plugins/superpowers
sh scripts/verify-codex-plugin.sh
```

Set up the [pinned Codex validators](plugins/superpowers/README.md#development-checks)
before running the verifier locally. It checks the plugin manifest, every skill,
role installer, routing contracts, and Codex-only runtime boundaries. GitHub Actions
provisions the validators and runs these checks on Linux and Windows PowerShell 7.
These are the supported platforms for this release.

See [CHANGES.md](CHANGES.md) for the differences from the upstream workflow.
See [RELEASE_NOTES.md](RELEASE_NOTES.md) for 6.4.2 changes and upgrade guidance.

## License and provenance

MIT licensed. This project is a streamlined fork of
[`pcvelz/superpowers`](https://github.com/pcvelz/superpowers), which adapts
[`obra/superpowers`](https://github.com/obra/superpowers) for Codex. See
[NOTICE](NOTICE) and the retained [LICENSE](plugins/superpowers/LICENSE).
