$ErrorActionPreference = 'Stop'

function Require-Text([string] $Path, [string] $Text) {
    $content = [IO.File]::ReadAllText($Path)
    if ($content.IndexOf($Text, [StringComparison]::Ordinal) -lt 0) {
        throw "FAIL: missing '$Text' in $Path"
    }
}

function Reject-Text([string] $Path, [string] $Text) {
    $content = [IO.File]::ReadAllText($Path)
    if ($content.IndexOf($Text, [StringComparison]::Ordinal) -ge 0) {
        throw "FAIL: unexpected '$Text' in $Path"
    }
}

function Reject-LegacyAliases([string] $Path) {
    $content = [IO.File]::ReadAllText($Path)
    if ($content -match '(?i)\b(haiku|sonnet|opus|fable|anthropic)\b') {
        throw "FAIL: legacy model alias remains in $Path"
    }
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$files = @(
    (Join-Path $repoRoot 'skills/shared/codex-routing.md'),
    (Join-Path $repoRoot 'skills/shared/task-format-reference.md'),
    (Join-Path $repoRoot 'skills/brainstorming/SKILL.md'),
    (Join-Path $repoRoot 'skills/brainstorming/spec-document-reviewer-prompt.md'),
    (Join-Path $repoRoot 'skills/subagent-driven-development/SKILL.md'),
    (Join-Path $repoRoot 'skills/subagent-driven-development/implementer-prompt.md'),
    (Join-Path $repoRoot 'skills/subagent-driven-development/spec-reviewer-prompt.md'),
    (Join-Path $repoRoot 'skills/subagent-driven-development/code-quality-reviewer-prompt.md'),
    (Join-Path $repoRoot 'skills/subagent-driven-development/task-reviewer-prompt.md'),
    (Join-Path $repoRoot 'skills/subagent-driven-development/re-review-prompt.md'),
    (Join-Path $repoRoot 'skills/dispatching-parallel-agents/SKILL.md'),
    (Join-Path $repoRoot 'skills/codex-agent-routing/SKILL.md'),
    (Join-Path $repoRoot 'skills/executing-plans/SKILL.md'),
    (Join-Path $repoRoot 'skills/requesting-code-review/SKILL.md'),
    (Join-Path $repoRoot 'skills/requesting-code-review/code-reviewer.md'),
    (Join-Path $repoRoot 'skills/test-driven-development/SKILL.md'),
    (Join-Path $repoRoot 'skills/using-git-worktrees/SKILL.md'),
    (Join-Path $repoRoot 'skills/finishing-a-development-branch/SKILL.md'),
    (Join-Path $repoRoot 'skills/using-superpowers/SKILL.md'),
    (Join-Path $repoRoot 'skills/using-superpowers/references/codex-tools.md'),
    (Join-Path $repoRoot 'skills/writing-plans/SKILL.md'),
    (Join-Path $repoRoot 'skills/writing-plans/plan-document-reviewer-prompt.md'),
    (Join-Path $repoRoot 'skills/specifying-gates/SKILL.md')
)

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "FAIL: missing skill file: $file"
    }
}

$subagentSkill = Join-Path $repoRoot 'skills/subagent-driven-development/SKILL.md'
$routingGuide = Join-Path $repoRoot 'skills/shared/codex-routing.md'
$dispatchSkill = Join-Path $repoRoot 'skills/dispatching-parallel-agents/SKILL.md'
$executingPlansSkill = Join-Path $repoRoot 'skills/executing-plans/SKILL.md'
$agentRoutingSkill = Join-Path $repoRoot 'skills/codex-agent-routing/SKILL.md'
$reviewSkill = Join-Path $repoRoot 'skills/requesting-code-review/SKILL.md'
$usingSuperpowersSkill = Join-Path $repoRoot 'skills/using-superpowers/SKILL.md'
$codexToolsGuide = Join-Path $repoRoot 'skills/using-superpowers/references/codex-tools.md'
$planningSkill = Join-Path $repoRoot 'skills/writing-plans/SKILL.md'
$reviewPackage = Join-Path $repoRoot 'scripts/review-package'

if (-not (Test-Path -LiteralPath $reviewPackage -PathType Leaf)) {
    throw "FAIL: documented review-package command is missing: $reviewPackage"
}

foreach ($role in @(
    'superpowers_luna_implementer',
    'superpowers_terra_implementer',
    'superpowers_astra_implementer',
    'superpowers_astra_reviewer'
)) {
    Require-Text $subagentSkill $role
}

Require-Text $subagentSkill 'spawn_agent'
Require-Text $subagentSkill 'fork_turns: none'
Require-Text $subagentSkill 'never silently substitute'
Require-Text $routingGuide '## Host Capability Gate'
Require-Text $routingGuide "host's callable tool list"
Require-Text $routingGuide 'single-agent mode'
Require-Text $routingGuide 'must not claim'
Require-Text $routingGuide 'install-codex-agents.ps1'
Require-Text $routingGuide 'resolve-codex-role.ps1'
Require-Text $routingGuide 'current platform'
Require-Text $subagentSkill 'requires routed mode'
Require-Text $dispatchSkill 'single-agent mode'
Require-Text $planningSkill 'modelTier'
Require-Text $executingPlansSkill 'spawn_agent'
Require-Text $executingPlansSkill 'single-agent mode'
Require-Text $agentRoutingSkill "host's callable tool list"
Require-Text $reviewSkill 'superpowers_astra_reviewer'
Require-Text $reviewSkill 'independent review unavailable'
Require-Text $usingSuperpowersSkill 'host capability gate'
Require-Text $codexToolsGuide 'single-agent mode'
Require-Text $usingSuperpowersSkill 'Direct'
Require-Text $usingSuperpowersSkill 'controller implements directly'
Require-Text (Join-Path $repoRoot 'skills/brainstorming/SKILL.md') 'No redundant approval'
Require-Text (Join-Path $repoRoot 'skills/brainstorming/SKILL.md') 'No mandatory document, commit, task tracker, or separate spec review'
Require-Text $planningSkill 'Controller execution is the normal default'
Require-Text $planningSkill 'highRiskBoundary'
Require-Text $reviewSkill 'Independent review is a risk control, not a ritual'
Require-Text $reviewSkill 'Mechanical/trivial'
Require-Text (Join-Path $repoRoot 'skills/test-driven-development/SKILL.md') 'Test behavior, not every new function or method'
Require-Text (Join-Path $repoRoot 'skills/test-driven-development/SKILL.md') 'Refactoring is optional cleanup'
Require-Text (Join-Path $repoRoot 'skills/using-git-worktrees/SKILL.md') 'Do not create a worktree merely because a plan exists'
Require-Text (Join-Path $repoRoot 'skills/using-git-worktrees/SKILL.md') 'Do not automatically install'
Require-Text $subagentSkill 'Per-task independent review is REQUIRED only'
Require-Text $subagentSkill 'exactly one fresh independent whole-diff review'
Require-Text $routingGuide 'Ordinary delegated tasks complete from implementer evidence plus controller'
Require-Text $routingGuide 'reruns only evidence'
Require-Text (Join-Path $repoRoot 'skills/shared/task-format-reference.md') 'highRiskBoundary: true'
Require-Text (Join-Path $repoRoot 'skills/shared/task-format-reference.md') 'Ordinary tasks'
Require-Text $planningSkill 'requires one task-scoped independent review'
Require-Text $reviewSkill 'Required task-scoped review'
Require-Text $subagentSkill 'includes the committed range, index, working tree, and untracked files'
Require-Text (Join-Path $repoRoot 'skills/subagent-driven-development/implementer-prompt.md') '[BRIEF_FILE]'
Require-Text (Join-Path $repoRoot 'skills/subagent-driven-development/implementer-prompt.md') '[REPORT_FILE]'
Require-Text (Join-Path $repoRoot 'skills/subagent-driven-development/implementer-prompt.md') 'Write your complete implementation and evidence report'
Require-Text $dispatchSkill 'superpowers_terra_implementer'
Require-Text $dispatchSkill 'fork_turns: none'
Reject-Text $dispatchSkill 'Subagent (general-purpose)'
Require-Text (Join-Path $repoRoot 'skills/finishing-a-development-branch/SKILL.md') 'is not ownership proof'
Require-Text (Join-Path $repoRoot 'skills/finishing-a-development-branch/SKILL.md') 'mandatory cleanup helper'
Require-Text (Join-Path $repoRoot 'skills/finishing-a-development-branch/SKILL.md') 'Never use location, apparent staleness, or a broad'
foreach ($reviewerPrompt in @(
    'skills/brainstorming/spec-document-reviewer-prompt.md',
    'skills/writing-plans/plan-document-reviewer-prompt.md',
    'skills/subagent-driven-development/spec-reviewer-prompt.md',
    'skills/subagent-driven-development/code-quality-reviewer-prompt.md',
    'skills/subagent-driven-development/task-reviewer-prompt.md',
    'skills/subagent-driven-development/re-review-prompt.md',
    'skills/requesting-code-review/code-reviewer.md'
)) {
    $reviewerPath = Join-Path $repoRoot $reviewerPrompt
    Require-Text $reviewerPath 'superpowers_astra_reviewer'
    Require-Text $reviewerPath 'Verdict: ship | fix-first | rethink'
}
Require-Text (Join-Path $repoRoot 'skills/requesting-code-review/code-reviewer.md') 'Do not create or enter worktrees'
Require-Text $executingPlansSkill 'A written plan does not make a worktree mandatory'
Require-Text (Join-Path $repoRoot 'skills/specifying-gates/SKILL.md') 'Do not impose one-question-at-a-time ceremony'
Reject-Text $subagentSkill 'rounds 1-3'
Reject-Text $subagentSkill 'Never skip the task review'
Reject-Text (Join-Path $repoRoot 'skills/test-driven-development/SKILL.md') 'Every new function/method has a test'
Reject-Text (Join-Path $repoRoot 'skills/specifying-gates/SKILL.md') "one question at a time per the brainstorming skill's rule"

foreach ($leafPrompt in @(
    'skills/subagent-driven-development/implementer-prompt.md',
    'skills/subagent-driven-development/task-reviewer-prompt.md',
    'skills/subagent-driven-development/re-review-prompt.md',
    'skills/requesting-code-review/code-reviewer.md'
)) {
    Require-Text (Join-Path $repoRoot $leafPrompt) 'You Do Not Dispatch Subagents'
}

foreach ($role in @(
    'agents/superpowers-luna-implementer.toml',
    'agents/superpowers-terra-implementer.toml',
    'agents/superpowers-astra-implementer.toml',
    'agents/superpowers-astra-reviewer.toml'
)) {
    Require-Text (Join-Path $repoRoot $role) 'never spawn'
}
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-implementer.toml') 'model = "gpt-6-astra"'
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-reviewer.toml') 'model = "gpt-6-astra"'
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-implementer.toml') 'name = "superpowers_astra_implementer"'
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-reviewer.toml') 'name = "superpowers_astra_reviewer"'
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-implementer.toml') 'model_reasoning_effort = "high"'
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-reviewer.toml') 'model_reasoning_effort = "high"'
Require-Text (Join-Path $repoRoot 'agents/superpowers-astra-reviewer.toml') 'sandbox_mode = "read-only"'
foreach ($wrapper in @('scripts/sdd-workspace', 'scripts/task-brief')) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $wrapper) -PathType Leaf)) {
        throw "FAIL: helper wrapper is missing: $wrapper"
    }
}
Require-Text $routingGuide 'Resolve every `scripts/...` path'
Require-Text $routingGuide 'plugin root'

foreach ($file in $files) {
    Reject-LegacyAliases $file
}

Write-Output 'All Codex skill routing contract tests passed.'
