# Superpowers Lite for Claude Code

The Claude Code edition of Superpowers Lite: structured planning, test-driven
development, systematic debugging, multi-agent execution, and verified delivery, with
process scaled to the risk of the task. It is a separate package from the Codex edition
in `../plugins/superpowers` and shares none of its runtime.

## Highlights

- Direct, Light, and Full workflows, so a small request does not pay for a design review.
- Four model-tiered subagents, defined in one place (`agents/*.md`) and chosen by plans
  through a `modelTier`, never a raw model ID.
- Fable 5.1 for frontier work and independent review, with an announced, recorded
  fallback to Opus 5.5 when Fable is unavailable.
- Leaf agents enforced by tool restrictions, and a reviewer with no edit tools.
- Instructions written for current Claude models: plain, reasoned sentences instead of
  capitalized commands.
- A small SessionStart note and `claude plugin validate --strict` plus contract tests in CI.

| Tier | Agent (`subagent_type`) | Model | Effort | Use | Fallback |
| --- | --- | --- | --- | --- | --- |
| mechanical | `superpowers-lite:mechanical-implementer` | Haiku 5.5 | medium | Small, fully specified work | none |
| standard | `superpowers-lite:standard-implementer` | Sonnet 5.5 | high | Integration and debugging | none |
| frontier | `superpowers-lite:frontier-implementer` | Fable 5.1 | high | Broad judgment, architecture | Opus 5.5 |
| review | `superpowers-lite:reviewer` | Fable 5.1 | high, read-only | Fresh, independent diff review | Opus 5.5 |

Keep routine work in the main session. Use the mechanical lane for precise briefs, the
standard lane for integration inside a settled design, and the frontier lane and reviewer
where judgment or an independent look pays for itself.

## Install

From Claude Code:

```text
/plugin marketplace add helloadamlee/superpowers-lite
/plugin install superpowers-lite@superpowers-lite
```

Or load a local checkout for development:

```bash
git clone https://github.com/helloadamlee/superpowers-lite.git
claude --plugin-dir superpowers-lite/claude
```

Start a new session after installing. Skills appear as `/superpowers-lite:<skill>` and
load automatically when their descriptions match the task. The `superpowers-lite`
namespace keeps this plugin separate from other Superpowers distributions.

## When Fable is unavailable

Fable 5.1 may not be available to every account, for example without usage credits or
entitlement for it. When a frontier or review dispatch fails with a model-access error
before any work starts, the controller:

1. tells you once which lane failed and why;
2. re-dispatches the same agent with `model: "opus"` (same effort);
3. records `model-fallback: <lane> fable -> opus` in the ledger or final report;
4. sends later frontier and review dispatches straight to Opus for that session.

If Opus also fails, delegation stops and you choose to restore access, change the task's
tier explicitly, or stop. Mechanical and standard lanes never change model on their own.
The full procedure is in [`skills/shared/claude-routing.md`](skills/shared/claude-routing.md).

To prefer Opus permanently (or any other model), edit `model:` in
`agents/frontier-implementer.md` and `agents/reviewer.md`. Agent files use the aliases
`haiku`, `sonnet`, `opus`, and `fable`, which resolve to the current model on your
provider (API, Bedrock, or Vertex); use a full model ID to pin a version.

## Configure your model policy

Plans reference tiers, so changing a model means editing one agent file. Keep the routing
table in `skills/shared/claude-routing.md` in step; `tests/claude-native/test-agent-contract.sh`
fails if they drift. Keep a role's effort when you change its model unless you have
evidence the new model needs more.

## Limits worth knowing

- The reviewer is read-only for edit tools (`Edit`, `Write`, `NotebookEdit` are removed)
  but keeps `Bash` for focused inspection, so its read-only behavior beyond that rests on
  its instructions. The Codex edition's sandbox enforced this at the host level.
- Plugin subagents run with the session's permission settings.
- `checking-gates` and `specifying-gates` describe an opt-in hook flow that this edition
  does not ship; they work as plain skills without it.

## Verify

```bash
sh scripts/verify-claude-plugin.sh
```

See [docs/testing.md](docs/testing.md) and [docs/development.md](docs/development.md). See [CHANGES.md](CHANGES.md) for how this edition
differs from the Codex edition.

## License and provenance

MIT licensed. This is a Claude Code adaptation of Superpowers Lite, itself a streamlined
fork of [`pcvelz/superpowers`](https://github.com/pcvelz/superpowers), which adapts
[`obra/superpowers`](https://github.com/obra/superpowers). See [NOTICE](NOTICE) and
[LICENSE](LICENSE).
