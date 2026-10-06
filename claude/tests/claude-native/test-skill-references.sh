#!/usr/bin/env bash
# Every skill cross-reference and relative link must resolve, and no skill may
# still use the old namespace or a retired tool name.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

skills="$plugin_root/skills"

# 1. superpowers-lite:<name> references point at a real skill or agent.
refs=$(grep -rhoE 'superpowers-lite:[a-z][a-z-]*' "$skills" "$plugin_root/agents" "$plugin_root/hooks" | sort -u)
for ref in $refs; do
  name=${ref#superpowers-lite:}
  if [ -f "$skills/$name/SKILL.md" ] || [ -f "$plugin_root/agents/$name.md" ]; then
    continue
  fi
  fail "unresolved reference: $ref"
done
pass "all superpowers-lite:* references resolve"

# 2. The pre-fork namespace must not survive anywhere in shipped content.
if grep -rnE 'superpowers:[a-z]' "$skills" "$plugin_root/agents" "$plugin_root/hooks"; then
  fail "old superpowers: namespace remains"
fi
pass "no old namespace"

# 3. Relative markdown links resolve.
status=0
while IFS= read -r file; do
  dir=$(dirname "$file")
  for target in $(grep -oE '\]\([^)#:]+(#[^)]*)?\)' "$file" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//'); do
    [ -n "$target" ] || continue
    [ -e "$dir/$target" ] || { printf 'broken link in %s: %s\n' "$file" "$target" >&2; status=1; }
  done
done < <(find "$skills" -name '*.md')
[ "$status" = 0 ] || fail "broken relative links"
pass "relative links resolve"

# 4. Skills discovered by Claude Code are exactly the directories holding a SKILL.md,
#    and each declares a matching name and a description.
for dir in "$skills"/*/; do
  name=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] || continue
  [ "$(frontmatter_field "$dir/SKILL.md" name)" = "$name" ] || fail "$name: frontmatter name must equal directory"
  [ -n "$(frontmatter_field "$dir/SKILL.md" description)" ] || fail "$name: description missing"
  len=$(frontmatter_field "$dir/SKILL.md" description | wc -c | tr -d ' ')
  [ "$len" -le 1536 ] || fail "$name: description exceeds 1536 characters"
done
[ ! -f "$skills/shared/SKILL.md" ] || fail "skills/shared must stay a plain reference directory, not a skill"
pass "skill frontmatter is valid"

# 5. Scripts referenced through the plugin root exist and are executable.
for script in $(grep -rhoE 'CLAUDE_PLUGIN_ROOT\}/scripts/[a-z-]+' "$skills" | sed 's#.*/scripts/##' | sort -u); do
  [ -x "$plugin_root/scripts/$script" ] || fail "referenced script missing or not executable: $script"
done
pass "referenced scripts exist"
printf 'All skill reference tests passed.\n'
