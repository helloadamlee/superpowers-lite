# Differences from the Codex edition

The workflow policy is the same: Direct, Light, and Full lanes, proportional testing and
review, one substantive fix wave per review, file-based briefs and review packages. What
changed is the host integration and the instruction style.

## Host integration

| Area | Codex edition | Claude Code edition |
| --- | --- | --- |
| Manifest | `.codex-plugin/plugin.json`, root `marketplace.json` | `.claude-plugin/plugin.json`, root `.claude-plugin/marketplace.json` |
| Plugin name | `superpowers` | `superpowers-lite` (skills are `superpowers-lite:<skill>`) |
| Roles | TOML templates copied into `~/.codex/agents` by an installer | Markdown agents auto-discovered from `agents/`; no installer |
| Delegation | `spawn_agent` with `fork_turns: none` | `Agent` tool with `subagent_type`; subagents start with fresh context |
| Role resolution | `resolve-codex-role` scripts (POSIX and PowerShell) | Table in `skills/shared/claude-routing.md`, checked against the agent files by a test |
| Leaf agents | By instruction | By instruction and by removing the `Agent` tool |
| Task tracking | `update_plan` | `TaskCreate`, `TaskUpdate`, `TaskList` |
| Worktrees | Host tool or Git | `EnterWorktree`/`ExitWorktree`, `Agent` `isolation: "worktree"`, or Git |
| Bootstrap | Skill discovery only | Skill discovery plus a static SessionStart note |
| Validation | Pinned Codex validators, Linux and PowerShell 7 | `claude plugin validate --strict`, Linux |
| Windows | PowerShell scripts | Claude Code on Windows runs the bash helpers through Git Bash |

## Model routing

| Tier | Codex edition | Claude Code edition |
| --- | --- | --- |
| mechanical | GPT-5.6 Luna, medium | Haiku 4.5, medium |
| standard | GPT-6.1 Sol, high | Sonnet 5.5, high |
| frontier | GPT-6 Astra, high | Fable 5.1, high; falls back to Opus 5.5 |
| review | GPT-6 Astra, high, read-only | Fable 5.1, high, no edit tools; falls back to Opus 5.5 |

The Codex edition never substitutes a model. This edition allows exactly one announced,
recorded substitution: Fable to Opus on the frontier and review lanes, because Fable is
a metered model some accounts cannot use. Any other unavailable model still stops and asks.

## Instruction style

- Emphatic commands (`NEVER`, `MUST`, "Iron Law", "Forbidden Responses") became plain
  sentences that carry their reason. Current Claude models follow reasoned instructions
  closely, and capitalized commands tend to be over-applied.
- `verification-before-completion` and `writing-skills` were rewritten for current Claude
  Code conventions (frontmatter limits, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PLUGIN_ROOT}`,
  `claude plugin validate`).
- Prompt templates for subagents describe the `Agent` call instead of Codex `spawn_agent`.

## Removed or moved

- Role installers, resolvers, and Codex-specific tests and CI jobs.
- `skills/codex-agent-routing` and the per-skill `agents/openai.yaml` metadata.
- `skills/shared` is a plain reference directory rather than a skill, so it adds no
  always-on context.
- Helper scripts (`task-brief`, `review-package`, `sdd-workspace`) live once in `scripts/`
  and are referenced through `${CLAUDE_PLUGIN_ROOT}`.
