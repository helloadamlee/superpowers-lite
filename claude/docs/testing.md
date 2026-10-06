# Testing the Claude Code Plugin

Run from this directory (`claude/`):

```bash
sh scripts/verify-claude-plugin.sh
```

The verifier needs the `claude` CLI, `jq`, and `bash`. It runs, in order:

1. JSON syntax checks for the manifest and hook files, and a version-drift check
   between `.claude-plugin/plugin.json` and `package.json`.
2. `claude plugin validate --strict` on the plugin and on the repository marketplace
   (`../.claude-plugin/marketplace.json`). Validation is local and needs no credentials.
3. `tests/claude-native/test-agent-contract.sh`: the four agents match the routing table
   (names, model aliases, effort), are leaf agents, the reviewer has no edit tools, and
   the Fable-to-Opus fallback contract is present.
4. `tests/claude-native/test-skill-references.sh`: every `superpowers-lite:*` reference,
   relative link, referenced script, and skill frontmatter field resolves.
5. `tests/claude-native/test-no-legacy-runtime.sh`: no Codex files or vocabulary ship.
6. `tests/systematic-debugging/test-find-polluter.sh`.

The visual companion server has its own suite:

```bash
cd tests/brainstorm-server && npm ci && npm test
```

## Manual smoke test

Load the plugin from disk and confirm the agents and the SessionStart note appear:

```bash
claude --plugin-dir . plugin details superpowers-lite
claude -p --plugin-dir . "List the subagent types from the superpowers-lite plugin."
```

To exercise a lane directly, ask Claude to call the `Agent` tool with
`subagent_type: superpowers-lite:frontier-implementer` and a trivial prompt, then repeat
with `model: "opus"` to confirm the override used by the Fable fallback.
