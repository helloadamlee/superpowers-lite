---
name: using-git-worktrees
description: Create or manage an isolated Git worktree when parallel, multi-agent, long, risky, or explicitly isolated work needs it; ordinary bounded work stays in the current safe workspace
---

# Using Git Worktrees

Use isolation when it pays for itself. A worktree is required for parallel or
multi-agent writers, long/risky work, or when the user, host, or repository requires
isolation. It is optional for ordinary Direct and Light work on a safe branch with a
cleanly understood working tree.

Do not create a worktree merely because a plan exists.

**Announce when used:** "I'm using the using-git-worktrees skill to set up an
isolated workspace."

## Decide Whether Isolation Is Needed

Use a worktree when any applies:

- multiple write-capable agents or parallel implementation streams;
- work is long, cross-cutting, destructive, migration-heavy, or otherwise risky;
- the current checkout contains unrelated user changes that need isolation;
- the user, repository instructions, or harness explicitly requires one.

Otherwise continue in the current safe branch/workspace. Inspect branch and status;
never overwrite unrelated changes. Do not force a worktree question into the flow
when instructions already settle the choice.

## Detect Existing Isolation

Before creating anything:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
git rev-parse --show-superproject-working-tree 2>/dev/null
```

`GIT_DIR != GIT_COMMON` also occurs in submodules, so use the superproject result as
a guard. If already in a linked worktree, do not nest another. Report the path and
branch/detached state, then perform only the setup and baseline work this task needs.

## Create the Workspace

### Prefer native or harness tools

Use the host's native worktree create/enter tool when available. It owns placement,
branch creation, session state, and cleanup. Follow repository and global lifecycle
instructions exactly, including any mandatory bootstrap immediately after creation.
Do not bypass a declared lifecycle command with raw Git.

Record provenance in the active plan ledger or task/session state immediately after
creation: creator (`native/harness`), controlling checkout, worktree path, branch,
bootstrap command/result, and the required exit/cleanup mechanism. The directory name
is never ownership proof.

### Git fallback

Only use `git worktree add` when no native/harness mechanism is available.

1. Honor an explicit worktree location from user or repository instructions.
2. Otherwise prefer an existing `.worktrees/`, then `worktrees/`, then default to
   project-local `.worktrees/`.
3. For a project-local directory, verify it is ignored before creation:

   ```bash
   git check-ignore -q .worktrees 2>/dev/null || \
     git check-ignore -q worktrees 2>/dev/null
   ```

4. If it is not ignored, add the precise directory to `.gitignore`. Commit that
   change only when the user or repository workflow authorizes commits.
5. Create an explicit branch and path:

   ```bash
   git worktree add "$path" -b "$BRANCH_NAME"
   cd "$path"
   ```

6. Record the same provenance fields with creator `git-fallback`, including the
   controlling checkout and any mandatory bootstrap/cleanup helper from active
   instructions.

If creation is blocked, report the failure. Fall back to the current workspace only
when doing so remains safe and does not violate an explicit isolation requirement.

## Project Setup Is Conditional

Inspect project instructions and the files relevant to the requested verification.
Do not automatically install every detected dependency or run a broad build.

Run setup only when the new workspace lacks something the selected build/test command
needs. Prefer an existing lockfile-preserving, project-documented command. Installing
dependencies changes local state and may use network access, so report what is needed
and follow the host's authorization rules.

Examples such as `npm install`, `cargo build`, `pip install`, or `go mod download`
are not automatic merely because their manifest exists.

## Baseline Verification Is Conditional

Choose a baseline that can distinguish a pre-existing failure from one caused by the
task:

- focused module/package tests for a bounded change;
- compiler, parser, linter, or smoke check for mechanical/configuration work;
- dependent tests for shared APIs;
- the full suite for broad, risky, or integration-heavy work.

Skip an expensive baseline only when existing fresh evidence or the nature of the
change makes it unnecessary; record that decision. If the selected baseline fails,
report the failure and determine whether it blocks the task. Do not automatically run
the full suite merely because the workspace is new.

Report the workspace path, branch state, setup performed (or skipped), and baseline
command/result.

## Cleanup

Follow the same owner that created the workspace:

1. Resolve the recorded provenance. If it is missing or names another session, do not
   remove the workspace.
2. From the recorded controlling checkout, run any repository/global cleanup helper
   required before exit/removal and wait for it to succeed.
3. Prefer the host's native exit/remove tool when native creation was used.
4. Use `git worktree remove` only for a recorded Git-fallback worktree and only from outside
   that worktree.
5. Never prune broadly or remove a worktree/branch owned by another session. Destructive discard
   still requires explicit user authorization.

Lifecycle ordering from `AGENTS.md` or the host is binding even when another
worktree tool is available.

## Quick Reference

| Situation | Action |
|---|---|
| Direct/Light, safe current workspace | Stay in place |
| Parallel/multi-agent writers | Worktree required |
| Long/risky or isolation requested | Worktree required |
| Already in linked worktree | Reuse; do not nest |
| Native/harness tool available | Use it and its bootstrap/cleanup lifecycle |
| Git fallback | Verify project-local directory is ignored |
| Bounded change | Focused baseline is acceptable |
| Broad/high-risk change | Broader or full baseline may be warranted |
| No setup needed | Do not install dependencies |
