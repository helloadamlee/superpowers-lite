---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## Host Capability Gate

Parallel dispatch requires routed mode from `skills/shared/codex-routing.md`.
Inspect the host's callable tool list before assigning agent work. If `spawn_agent`
is absent and the user did not explicitly require parallel agents, announce
single-agent mode and investigate the independent domains sequentially in the
controller. If parallel agents or subagents were explicitly required, stop and
explain that the host lacks the delegation capability. Never present sequential
controller work as parallel or independently reviewed agent work.

If `spawn_agent` is callable, use the exact Codex roles and failure behavior in the
shared routing contract; do not dispatch generic or inherited-model agents.

## When to Use

Multiple failures, but are they independent? If not — a single agent investigates all of them together. If yes — can they run in parallel (no shared state)? Shared state means sequential agents, one per problem domain; no shared state means parallel dispatch.

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures are related (fix one might fix others)
- Need to understand full system state
- Agents would interfere with each other

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken:
- File A tests: Tool approval flow
- File B tests: Batch completion behavior
- File C tests: Abort functionality

Each domain is independent - fixing tool approval doesn't affect abort tests.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One test file or subsystem
- **Clear goal:** Make these tests pass
- **Constraints:** Don't change other code
- **Expected output:** Summary of what you found and fixed

### 3. Dispatch in Parallel

Issue all three subagent dispatches in the same response — they run in parallel:

```text
Resolve each task's modelTier with the platform resolver. For these standard tasks:
spawn_agent(agent_type: superpowers_terra_implementer, fork_turns: none,
            task_name: "fix_agent_abort",
            message: "Fix agent-tool-abort.test.ts failures")
spawn_agent(agent_type: superpowers_terra_implementer, fork_turns: none,
            task_name: "fix_batch_completion",
            message: "Fix batch-completion-behavior.test.ts failures")
spawn_agent(agent_type: superpowers_terra_implementer, fork_turns: none,
            task_name: "fix_approval_races",
            message: "Fix tool-approval-race-conditions.test.ts failures")
# All three run concurrently.
```

Run the current-platform install check first and verify the exact routed role is
callable. Multiple dispatch calls in one response = parallel execution. One per
response = sequential. Never replace an unavailable exact role with a generic or
inherited-model agent.

### 4. Review and Integrate

When agents return:
- Read each summary
- Verify fixes don't conflict
- Run full test suite
- Integrate all changes

## Agent Prompt Structure

Good agent prompts are:
1. **Focused** - One clear problem domain
2. **Self-contained** - All context needed to understand the problem
3. **Specific about output** - What should the agent return?

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Return: Summary of what you found and what you fixed.
```

## Common Mistakes

**❌ Too broad:** "Fix all the tests" - agent gets lost
**✅ Specific:** "Fix agent-tool-abort.test.ts" - focused scope

**❌ No context:** "Fix the race condition" - agent doesn't know where
**✅ Context:** Paste the error messages and test names

**❌ No constraints:** Agent might refactor everything
**✅ Constraints:** "Do NOT change production code" or "Fix tests only"

**❌ Vague output:** "Fix it" - you don't know what changed
**✅ Specific:** "Return summary of root cause and changes"

## When NOT to Use

**Related failures:** Fixing one might fix others - investigate together first
**Need full context:** Understanding requires seeing entire system
**Exploratory debugging:** You don't know what's broken yet
**Shared state:** Agents would interfere (editing same files, using same resources)

## Real Example from Session

**Scenario:** 6 test failures across 3 files after major refactoring

**Failures:**
- agent-tool-abort.test.ts: 3 failures (timing issues)
- batch-completion-behavior.test.ts: 2 failures (tools not executing)
- tool-approval-race-conditions.test.ts: 1 failure (execution count = 0)

**Decision:** Independent domains - abort logic separate from batch completion separate from race conditions

**Dispatch:**
```
Agent 1 → Fix agent-tool-abort.test.ts
Agent 2 → Fix batch-completion-behavior.test.ts
Agent 3 → Fix tool-approval-race-conditions.test.ts
```

**Results:**
- Agent 1: Replaced timeouts with event-based waiting
- Agent 2: Fixed event structure bug (threadId in wrong place)
- Agent 3: Added wait for async tool execution to complete

**Integration:** All fixes independent, no conflicts, full suite green

## Verification

After agents return:
1. **Review each summary** - Understand what changed
2. **Check for conflicts** - Did agents edit same code?
3. **Run full suite** - Verify all fixes work together
4. **Spot check** - Agents can make systematic errors

---

## Native Task Integration

Track parallel agent work with structured native tasks.

### Before Dispatch

Create a task per agent with structured description:

```yaml
TaskCreate:
  subject: "[Agent assignment — concrete deliverable]"
  description: |
    **Goal:** [What this agent should produce]

    **Files:**
    - [Expected files to touch]

    **Acceptance Criteria:**
    - [ ] [Concrete criterion]

    **Verify:** [Command to verify agent's work]

    ```json:metadata
    {"files": ["expected/files"], "verifyCommand": "test command", "acceptanceCriteria": ["criterion"]}
    ```
```

See `skills/shared/task-format-reference.md` for the full task format reference.

### Monitor Progress

```
TaskList
```

### After Completion

When marking tasks completed via `TaskUpdate`, also sync `.tasks.json`:

1. Read `<plan-path>.tasks.json`
2. Set the task's `"status"` to `"completed"`
3. Set `"lastUpdated"` to current ISO timestamp
4. Write back

### Notes

- No blockedBy (parallel = independent)
- Controller is responsible for `.tasks.json` sync (not the dispatched agents)
