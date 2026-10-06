# Task Format Reference

Plan tasks carry a complete structured description and a JSON metadata fence.

Required sections:

- Goal
- Files
- Acceptance Criteria
- Verify

The metadata fence must contain:

```json
{"files":["path/to/file"],"verifyCommand":"command","acceptanceCriteria":["observable result"],"verificationScope":"focused","highRiskBoundary":false,"modelTier":"mechanical"}
```

Valid modelTier values are mechanical, standard, and frontier. They resolve through
the table in [claude-routing.md](claude-routing.md) to a Superpowers Lite subagent. A
task may also carry userGate, tags, requiresUserSpecification, gateScope, failurePolicy, and
subagentBrief when verification needs an explicit user decision.

Every acceptance criterion must name observable evidence. Every delegated task must
own an explicit file set and include its verification command. `verificationScope`
is `format`, `focused`, `dependent`, or `full`.

Set `highRiskBoundary: true` only for security/auth, concurrency, persistence or data
migration, public API/protocol compatibility, broad shared infrastructure, or an
explicit user-required task review. The marker is authoritative: the controller dispatches one fresh `superpowers-lite:reviewer` at that task boundary. Ordinary tasks
do not receive independent task review; implementer evidence plus controller
acceptance is sufficient. Full-lane work receives one final whole-diff review.

The coordinator inspects the actual diff and worker evidence before completion. It
reruns only evidence that is missing, doubtful, or invalidated by later changes, not
every worker command as a matter of ritual.
