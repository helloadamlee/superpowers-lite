---
name: writing-skills
description: Create or update Codex skills and verify their behavior before publication
---

# Writing Skills

Treat a skill as executable process documentation. It must have a focused
description, a valid SKILL.md frontmatter block, clear activation conditions, and
instructions that can be verified in a fresh Codex task.

## Test First

Write a pressure scenario before changing the skill. Run the baseline and record the
failure or missed behavior. Add the smallest instruction that closes that gap, run
the scenario again, and refactor only while the scenario remains green.

## Structure

Keep each skill's SKILL.md focused. Put supporting references beside it. Describe
observable inputs, actions, outputs, and failure behavior. Use Codex-native tools and
the exact role contract in skills/shared/codex-routing.md when delegation is needed.

## Review

Check frontmatter with the system skill validator, scan for stale host or model names,
and test the activation trigger in a new task. Do not claim a skill is ready until
the focused scenario and plugin validator pass.
