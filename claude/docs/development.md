# Developing the Claude Code Plugin

This directory is the Claude Code edition of Superpowers Lite. The Codex edition lives
in `../plugins/superpowers` and is separate: do not edit it from here, and do not copy
Codex runtime files, tool names, or model IDs into this tree.

- Model policy lives in `agents/*.md`; plans name a `modelTier`, never a model. The
  contract is `skills/shared/claude-routing.md`. Keep the two in sync; the agent
  contract test checks it.
- Frontier and review lanes prefer Fable and fall back to Opus, announced and recorded.
  No other lane falls back automatically.
- Implementers and reviewers are leaf agents (the `Agent` tool is disallowed) and the
  reviewer has no edit tools.
- Write instructions as plain, reasoned sentences. Reserve emphatic wording for a
  rule whose violation is costly and irreversible.

Before claiming completion, run `sh scripts/verify-claude-plugin.sh` and report its
output.
