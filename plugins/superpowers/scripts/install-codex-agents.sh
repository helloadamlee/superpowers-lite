#!/bin/sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
template_dir=$script_dir/../agents
codex_home_value=${CODEX_HOME-}
user_home_value=${HOME-}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf '%s\n' "Usage: install-codex-agents.sh [--target-dir PATH] [--check]"
}

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

sha256_file() {
  shasum -a 256 "$1" 2>/dev/null | awk 'NF >= 1 && length($1) == 64 { print $1; exit }'
}

roles='
superpowers-luna-implementer.toml
superpowers-terra-implementer.toml
superpowers-astra-implementer.toml
superpowers-astra-reviewer.toml
'

check_only=0
target_dir=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir)
      [ "$#" -ge 2 ] || fail "--target-dir requires a path"
      target_dir=$2
      shift 2
      ;;
    --check)
      check_only=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

if [ -z "$target_dir" ]; then
  if [ -n "$codex_home_value" ]; then
    target_dir=$codex_home_value/agents
  elif [ -n "$user_home_value" ]; then
    target_dir=$user_home_value/.codex/agents
  else
    fail "HOME or CODEX_HOME must be set, or pass --target-dir"
  fi
fi

case "$target_dir" in
  /*) ;;
  *) target_dir=$(pwd -P)/$target_dir ;;
esac

[ "$target_dir" != "/" ] || fail "refusing to use filesystem root"
[ -d "$template_dir" ] || fail "template directory is missing: $template_dir"

if path_exists "$target_dir" && { [ -L "$target_dir" ] || [ ! -d "$target_dir" ]; }; then
  fail "target directory is not a real directory: $target_dir"
fi

if [ "$check_only" -eq 1 ] && [ ! -d "$target_dir" ]; then
  fail "target directory is missing: $target_dir"
fi

if [ "$check_only" -eq 0 ] && [ ! -d "$target_dir" ]; then
  mkdir -p "$target_dir"
fi

for role in $roles; do
  template=$template_dir/$role
  destination=$target_dir/$role
  [ -f "$template" ] && [ ! -L "$template" ] || fail "invalid shipped template: $template"

  if [ "$check_only" -eq 1 ]; then
    [ -f "$destination" ] && [ ! -L "$destination" ] || fail "missing role: $destination"
    cmp -s "$template" "$destination" || fail "role differs from template: $destination"
    continue
  fi

  if [ -L "$destination" ]; then
    fail "refusing symlink destination: $destination"
  fi

  if [ -e "$destination" ]; then
    [ -f "$destination" ] || fail "refusing non-regular destination: $destination"
    cmp -s "$template" "$destination" || fail "refusing modified destination: $destination"
    continue
  fi

  staged=$(mktemp "$target_dir/.superpowers-agent.XXXXXX") || fail "could not stage $destination"
  cp "$template" "$staged" || fail "could not copy $template"
  if ! ln "$staged" "$destination"; then
    rm -f "$staged"
    fail "destination changed during installation: $destination"
  fi
  rm -f "$staged"
  printf 'INSTALLED: %s\n' "$destination"
done

if [ "$check_only" -eq 1 ]; then
  printf '%s\n' "CHECK PASSED: all Codex roles match their templates"
else
  printf '%s\n' "INSTALLATION COMPLETE: Codex roles are ready"
fi
