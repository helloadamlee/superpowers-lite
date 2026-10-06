---
name: writing-skills
description: Use when creating or editing a Claude Code skill, and before publishing one, to write it so Claude finds it, follows it, and it is verified in a fresh session
---

# Writing Skills

Treat a skill as executable process documentation. It needs a focused description,
valid `SKILL.md` frontmatter, clear activation conditions, and instructions you have
watched work in a fresh session.

## Test First

Write a pressure scenario before changing the skill. Run the baseline and record the
failure or missed behavior. Add the smallest instruction that closes that gap, run the
scenario again, and refactor only while the scenario still passes.

## Structure

- **Frontmatter:** `name` (matches the directory) and a `description` that says what the
  skill does and when to use it. Claude decides whether to load a skill from the
  description alone, so lead with the trigger and keep the combined description under
  the 1,536-character limit. Add `disable-model-invocation: true` for workflows that
  should only run when the user asks for them.
- **Body:** keep `SKILL.md` focused. Put long references, templates, and scripts in
  files beside it and link to them so they load only when needed. Refer to bundled
  files through `${CLAUDE_SKILL_DIR}` and to plugin scripts through
  `${CLAUDE_PLUGIN_ROOT}`.
- **Content:** describe observable inputs, actions, outputs, and failure behavior.
  Explain why a rule exists; a rule with its reason is followed more reliably, and in
  more situations, than a bare command. Reserve emphatic wording for the rare rule where
  a mistake is costly and irreversible.
- **Delegation:** when the skill dispatches agents, use the `Agent` tool and the
  contract in `skills/shared/claude-routing.md`.

## Review

Run `claude plugin validate --strict` on the plugin, scan for stale tool or model names,
and test the activation trigger in a new session. A skill is ready when the focused
scenario passes and the validator is clean.
