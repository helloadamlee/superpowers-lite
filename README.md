# Superpowers Lite

A lighter take on [Superpowers](https://github.com/obra/superpowers): planning,
test-first development, debugging, and independent review that **scale to the size of
the task**. A one-line fix just gets done. A risky migration gets a design, a plan, and
a fresh review.

- **Right-sized process:** Direct, Light, and Full workflows, chosen by risk, not file count.
- **Model-tiered subagents:** cheap models for mechanical work, the strongest for judgment and review.
- **Evidence over claims:** completion needs fresh test output, and reviews check the real diff.
- **Predictable delegation:** fixed roles and no silent model swaps.

## Pick your edition

| Edition | Install | Details |
| --- | --- | --- |
| **Claude Code** | `/plugin marketplace add helloadamlee/superpowers-lite`<br>`/plugin install superpowers-lite@superpowers-lite` | [Claude Code edition](claude/README.md): Haiku, Sonnet, and Fable subagents, with an announced Opus fallback |
| **Codex** | Marketplace add, plugin add, then the role installer: [steps](plugins/superpowers/README.md#installation) | [Codex edition](plugins/superpowers/README.md): GPT-5.6 Luna, GPT-6.1 Sol, and GPT-6 Astra roles |

Start a new session after installing so the skills and agents are discovered. Each
edition's README covers upgrades, model-policy customization, and its verification
checks.

See [CHANGES.md](CHANGES.md) for how the Codex edition differs from upstream and
[claude/CHANGES.md](claude/CHANGES.md) for how the Claude Code edition differs from it.
Release history is in [RELEASE_NOTES.md](RELEASE_NOTES.md).

## License and provenance

MIT licensed. A streamlined fork of [`pcvelz/superpowers`](https://github.com/pcvelz/superpowers),
which adapts [`obra/superpowers`](https://github.com/obra/superpowers). See
[NOTICE](NOTICE) and [claude/NOTICE](claude/NOTICE).
