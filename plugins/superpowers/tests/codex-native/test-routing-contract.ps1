Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Resolver = Join-Path $RepoRoot 'scripts\resolve-codex-role.ps1'
$PowerShellExe = (Get-Process -Id $PID).Path

function Invoke-Resolver([string[]] $Arguments) {
    $savedErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $Resolver @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) -join "`n" }
}

foreach ($case in @(
    @('mechanical', 'superpowers_luna_implementer'),
    @('standard', 'superpowers_terra_implementer'),
    @('frontier', 'superpowers_astra_implementer'),
    @('review', 'superpowers_astra_reviewer')
)) {
    $result = Invoke-Resolver @($case[0])
    if ($result.ExitCode -ne 0 -or $result.Output.Trim() -ne $case[1]) {
        throw "FAIL: tier $($case[0]) did not resolve to $($case[1])"
    }
}

foreach ($arguments in @(@(), @('unknown'), @('Mechanical'), @('standard', 'extra'))) {
    $result = Invoke-Resolver $arguments
    if ($result.ExitCode -eq 0 -or $result.Output -notmatch 'ERROR:') {
        throw 'FAIL: invalid resolver arguments were accepted'
    }
}

Write-Output 'All PowerShell Codex routing contract tests passed.'
