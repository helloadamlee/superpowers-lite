Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail([string] $Message) {
    [Console]::Error.WriteLine("ERROR: $Message")
    exit 1
}

function Get-PythonCommand {
    $py = Get-Command 'py' -ErrorAction SilentlyContinue
    if ($null -ne $py) { return @{ Command = $py.Source; Prefix = @('-3') } }
    foreach ($name in @('python', 'python3')) {
        $candidate = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $candidate) { return @{ Command = $candidate.Source; Prefix = @() } }
    }
    Fail 'Python is required for the canonical Codex validators'
}

function Invoke-CheckedProcess([string] $Command, [string[]] $Arguments, [string] $Description) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        Fail "$Description failed with exit code $LASTEXITCODE"
    }
}

function Invoke-PythonValidator($Python, [string] $Validator, [string] $Target, [string] $Description) {
    $arguments = @($Python.Prefix)
    $arguments += $Validator
    $arguments += $Target
    $command = $Python.Command
    Invoke-CheckedProcess $command $arguments $Description
}

$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Manifest = Join-Path $RepoRoot '.codex-plugin\plugin.json'

if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
    Fail "Codex manifest is missing: $Manifest"
}
try {
    $null = [IO.File]::ReadAllText($Manifest) | ConvertFrom-Json
} catch {
    Fail "Codex manifest is invalid: $($_.Exception.Message)"
}

$CodexHome = $env:CODEX_HOME
if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    $userProfile = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    }
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        Fail 'USERPROFILE or CODEX_HOME must be set to locate installed Codex validators'
    }
    $CodexHome = Join-Path $userProfile '.codex'
}

$ValidatorRoot = $env:CODEX_VALIDATOR_ROOT
if ([string]::IsNullOrWhiteSpace($ValidatorRoot)) {
    $ValidatorRoot = Join-Path (Join-Path $CodexHome 'skills') '.system'
}
$SkillValidator = Join-Path $ValidatorRoot 'skill-creator\scripts\quick_validate.py'
$PluginValidator = Join-Path $ValidatorRoot 'plugin-creator\scripts\validate_plugin.py'

foreach ($validator in @($SkillValidator, $PluginValidator)) {
    if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) {
        Fail "validator is missing: $validator"
    }
}

$RuntimeFiles = @(
    (Join-Path $RepoRoot 'scripts\install-codex-agents.sh'),
    (Join-Path $RepoRoot 'scripts\install-codex-agents.ps1'),
    (Join-Path $RepoRoot 'scripts\resolve-codex-role.sh'),
    (Join-Path $RepoRoot 'scripts\resolve-codex-role.ps1'),
    (Join-Path $RepoRoot 'scripts\sdd-workspace'),
    (Join-Path $RepoRoot 'scripts\task-brief'),
    (Join-Path $RepoRoot 'scripts\review-package'),
    (Join-Path $RepoRoot 'scripts\verify-codex-plugin.sh'),
    (Join-Path $RepoRoot 'scripts\verify-codex-plugin.ps1')
)
$FocusedTests = @(
    (Join-Path $RepoRoot 'tests\codex-native\test-install-codex-agents.ps1'),
    (Join-Path $RepoRoot 'tests\codex-native\test-routing-contract.ps1'),
    (Join-Path $RepoRoot 'tests\codex-native\test-skill-routing-contract.ps1'),
    (Join-Path $RepoRoot 'tests\codex-native\test-no-legacy-runtime.ps1')
)

foreach ($runtimeFile in $RuntimeFiles) {
    if (-not (Test-Path -LiteralPath $runtimeFile -PathType Leaf)) {
        Fail "runtime script is missing: $runtimeFile"
    }
}
foreach ($testFile in $FocusedTests) {
    if (-not (Test-Path -LiteralPath $testFile -PathType Leaf)) {
        Fail "focused test is missing: $testFile"
    }
}

$PowerShellExe = (Get-Process -Id $PID).Path
foreach ($testFile in $FocusedTests) {
    Invoke-CheckedProcess $PowerShellExe @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $testFile) "focused test '$testFile'"
}

$Workflow = [IO.Path]::GetFullPath((Join-Path $RepoRoot '..\..\.github\workflows\verify.yml'))
if (-not (Test-Path -LiteralPath $Workflow -PathType Leaf)) {
    Fail "verification workflow is missing: $Workflow"
}
$workflowText = [IO.File]::ReadAllText($Workflow)
foreach ($jobId in @('linux', 'windows-powershell-5', 'windows-powershell-7')) {
    if ($workflowText.IndexOf("  $jobId`:", [StringComparison]::Ordinal) -lt 0) {
        Fail "verification workflow is missing job: $jobId"
    }
}

$Python = Get-PythonCommand
$SkillFiles = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'skills') -Filter 'SKILL.md' -File -Recurse)
foreach ($skillFile in $SkillFiles) {
    Invoke-PythonValidator $Python $SkillValidator $skillFile.Directory.FullName "skill validator for '$($skillFile.Directory.FullName)'"
}
Invoke-PythonValidator $Python $PluginValidator $RepoRoot 'plugin validator'

$ScanFiles = @()
$ScanFiles += @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot '.codex-plugin') -File -Recurse)
$ScanFiles += @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'skills') -File -Recurse)
foreach ($runtimeFile in $RuntimeFiles) {
    $ScanFiles += Get-Item -LiteralPath $runtimeFile
}
$ScanFiles += Get-Item -LiteralPath (Join-Path $RepoRoot 'README.md')
$ScanFiles += Get-Item -LiteralPath (Join-Path $RepoRoot 'package.json')

$ForbiddenNames = @(
    ('hai' + 'ku'),
    ('son' + 'net'),
    ('op' + 'us'),
    ('fa' + 'ble'),
    ('anthro' + 'pic'),
    ('clau' + 'de'),
    ('open' + 'code'),
    ('gem' + 'ini')
)
$ForbiddenPattern = '(?i)\b(' + ($ForbiddenNames -join '|') + ')\b'
$ForbiddenMatchFound = $false
foreach ($scanFile in $ScanFiles) {
    $lineNumber = 0
    foreach ($line in [IO.File]::ReadLines($scanFile.FullName)) {
        $lineNumber++
        if ([regex]::IsMatch($line, $ForbiddenPattern)) {
            [Console]::Out.WriteLine(('{0}:{1}:{2}' -f $scanFile.FullName, $lineNumber, $line))
            $ForbiddenMatchFound = $true
        }
    }
}
if ($ForbiddenMatchFound) {
    Fail 'legacy host or model identifier remains in shipped runtime files'
}

[Console]::Out.WriteLine('Codex plugin verification passed.')
