# Codex Tool Mapping

Superpowers uses these Codex-native equivalents:

| Workflow need | Codex equivalent |
| --- | --- |
| Load a skill | Native skill loading |
| Track plan tasks | update_plan and the Codex task tracker |
| Delegate implementation | spawn_agent with a pinned custom-agent role |
| Wait for a delegated worker | wait_agent |
| Inspect and edit files | Native shell and file tools |

First inspect the host's callable tool list. If spawn_agent is absent, use the shared
contract's explicit single-agent mode or stop when delegation is required. In routed
mode, delegation always uses an exact role from skills/shared/codex-routing.md and
fork_turns: none. The coordinator verifies the role templates before dispatch.
