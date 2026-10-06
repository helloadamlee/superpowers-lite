#!/usr/bin/env bash
# The four routing agents must match the table in skills/shared/claude-routing.md:
# exact names, pinned models and effort, leaf-agent tool restrictions, read-only reviewer.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

agents="$plugin_root/agents"
routing="$plugin_root/skills/shared/claude-routing.md"
[ -f "$routing" ] || fail "routing contract is missing"

check_agent() {
  name=$1 model=$2 effort=$3
  file="$agents/$name.md"
  [ -f "$file" ] || fail "agent file is missing: $name"
  [ "$(frontmatter_field "$file" name)" = "$name" ] || fail "$name: frontmatter name mismatch"
  [ "$(frontmatter_field "$file" model)" = "$model" ] || fail "$name: expected model $model"
  [ "$(frontmatter_field "$file" effort)" = "$effort" ] || fail "$name: expected effort $effort"
  frontmatter_field "$file" disallowedTools | grep -Eq '(^|, )Agent(,|$)' ||
    fail "$name: leaf agents must disallow the Agent tool"
  [ -n "$(frontmatter_field "$file" description)" ] || fail "$name: description is empty"
  # The routing table row for this agent must state the same alias and effort.
  row=$(grep -F "superpowers-lite:$name" "$routing" | head -n 1)
  [ -n "$row" ] || fail "$name: not listed in the routing contract"
  printf '%s' "$row" | grep -Fq "\`$model\`" || fail "$name: routing table model differs from agent file"
  printf '%s' "$row" | grep -Fq "| $effort" || fail "$name: routing table effort differs from agent file"
  pass "$name -> $model / $effort"
}

check_agent mechanical-implementer haiku medium
check_agent standard-implementer sonnet high
check_agent frontier-implementer fable high
check_agent reviewer fable high

disallowed=$(frontmatter_field "$agents/reviewer.md" disallowedTools)
for tool in Edit Write NotebookEdit; do
  printf '%s' "$disallowed" | grep -Fq "$tool" || fail "reviewer must disallow $tool"
done
pass "reviewer is read-only for edit tools"

# Exactly these four agents ship; a stray extra one would escape the contract.
count=$(find "$agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
[ "$count" = 4 ] || fail "expected 4 agent files, found $count"
pass "agent set is exactly four"

# Fable fallback contract: both Fable lanes name opus, and the model parameter rule is stated.
for lane in frontier-implementer reviewer; do
  grep -F "superpowers-lite:$lane" "$routing" | head -n 1 | grep -Fq '`opus`' ||
    fail "$lane: routing table must name the opus fallback"
done
grep -Fq 'model-fallback:' "$routing" || fail "fallback record format is missing"
grep -Fq '`sonnet`, `opus`,' "$routing" || fail "model parameter alias rule is missing"
pass "Fable fallback contract is present"
printf 'All agent contract tests passed.\n'
