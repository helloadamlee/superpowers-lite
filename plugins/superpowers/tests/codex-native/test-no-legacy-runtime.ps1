$ErrorActionPreference = 'Stop'

function Assert-Absent([string] $RepoRoot, [string] $RelativePath) {
    $path = Join-Path $RepoRoot $RelativePath
    if (Test-Path -LiteralPath $path) {
        throw "FAIL: legacy path remains: $RelativePath"
    }

    Write-Output "PASS: absent $RelativePath"
}

function Require-Text([string] $Path, [string] $Text) {
    $content = [IO.File]::ReadAllText($Path)
    if ($content.IndexOf($Text, [StringComparison]::Ordinal) -lt 0) {
        throw "FAIL: missing '$Text' in $Path"
    }
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))

foreach ($relativePath in @(
    '.claude-plugin',
    'hooks',
    'commands',
    'CLAUDE.md',
    'GEMINI.md',
    'docs/README.opencode.md',
    'docs/windows'
)) {
    Assert-Absent $repoRoot $relativePath
}

$agentRoutingSkill = Join-Path $repoRoot 'skills/codex-agent-routing/SKILL.md'
Require-Text $agentRoutingSkill 'install-codex-agents.sh'
Require-Text $agentRoutingSkill 'Restore access'

Write-Output 'All Codex runtime cleanup tests passed.'
