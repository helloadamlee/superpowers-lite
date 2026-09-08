Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Installer = Join-Path $RepoRoot 'scripts\install-codex-agents.ps1'
$PowerShellExe = (Get-Process -Id $PID).Path
$RoleNames = @(
    'superpowers-luna-implementer.toml',
    'superpowers-terra-implementer.toml',
    'superpowers-astra-implementer.toml',
    'superpowers-astra-reviewer.toml'
)
$Fixture = Join-Path ([IO.Path]::GetTempPath()) ('superpowers-agent-test.' + [Guid]::NewGuid().ToString('N'))
$Junctions = @()
$SymbolicLinks = @()
$RaceJob = $null
$OriginalCodexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
$OriginalUserProfile = [Environment]::GetEnvironmentVariable('USERPROFILE', 'Process')

function Fail([string] $Message) {
    throw "FAIL: $Message"
}

function Invoke-Installer([string[]] $Arguments, [string] $ScriptPath = $Installer) {
    $savedErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output) -join "`n"
    }
}

function Assert-Success($Result, [string] $Context) {
    if ($Result.ExitCode -ne 0) {
        Fail "$Context failed with exit code $($Result.ExitCode): $($Result.Output)"
    }
}

function Assert-Failure($Result, [string] $Context) {
    if ($Result.ExitCode -eq 0) {
        Fail "$Context unexpectedly succeeded: $($Result.Output)"
    }
}

function Assert-Equal($Expected, $Actual, [string] $Context) {
    if ($Expected -ne $Actual) {
        Fail "$Context (expected '$Expected', actual '$Actual')"
    }
}

function Assert-SameFile([string] $ExpectedPath, [string] $ActualPath) {
    if (-not [IO.File]::Exists($ActualPath)) {
        Fail "missing file: $ActualPath"
    }

    [byte[]] $expectedBytes = [IO.File]::ReadAllBytes($ExpectedPath)
    [byte[]] $actualBytes = [IO.File]::ReadAllBytes($ActualPath)
    if ($expectedBytes.Length -ne $actualBytes.Length) {
        Fail "files differ in length: $ExpectedPath and $ActualPath"
    }

    for ($index = 0; $index -lt $expectedBytes.Length; $index++) {
        if ($expectedBytes[$index] -ne $actualBytes[$index]) {
            Fail "files differ at byte $index`: $ExpectedPath and $ActualPath"
        }
    }
}

function Get-DirectorySnapshot([string] $LiteralPath) {
    $lines = @()
    foreach ($item in @(Get-ChildItem -LiteralPath $LiteralPath -Force | Sort-Object -Property Name)) {
        $length = -1
        $contents = ''
        if ($item -is [IO.FileInfo]) {
            $length = $item.Length
            $contents = [Convert]::ToBase64String([IO.File]::ReadAllBytes($item.FullName))
        }
        $lines += '{0}|{1}|{2}|{3}|{4}' -f $item.Name, [int] $item.Attributes, $length, $item.LastWriteTimeUtc.Ticks, $contents
    }
    return $lines -join "`n"
}

function Assert-NoStagingFiles([string] $LiteralPath, [string] $Context) {
    if (-not [IO.Directory]::Exists($LiteralPath)) {
        return
    }
    $stagingFiles = @(Get-ChildItem -LiteralPath $LiteralPath -Force | Where-Object { $_.Name -like '.superpowers-agent.*' })
    if ($stagingFiles.Count -ne 0) {
        Fail "$Context left staging files in $LiteralPath"
    }
}

function Assert-AllRoles([string] $TargetDir, [string] $TemplateRoot = $RepoRoot) {
    foreach ($role in $RoleNames) {
        Assert-SameFile (Join-Path $TemplateRoot "agents\$role") (Join-Path $TargetDir $role)
    }
    Assert-Equal $RoleNames.Count @([IO.Directory]::GetFiles($TargetDir)).Count "unexpected file count in $TargetDir"
    Assert-NoStagingFiles $TargetDir 'successful installation'
}

function Wait-ForPath([string] $LiteralPath, [int] $TimeoutMilliseconds) {
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        if ([IO.File]::Exists($LiteralPath) -or [IO.Directory]::Exists($LiteralPath)) {
            return $true
        }
        Start-Sleep -Milliseconds 10
    }
    return $false
}

function New-Junction([string] $JunctionPath, [string] $TargetPath, [string] $CmdPath) {
    $command = 'mklink /J "{0}" "{1}"' -f $JunctionPath, $TargetPath
    $null = & $CmdPath /d /c $command 2>&1
    if ($LASTEXITCODE -ne 0 -or -not [IO.Directory]::Exists($JunctionPath)) {
        return $false
    }
    $script:Junctions += $JunctionPath
    return $true
}

[IO.Directory]::CreateDirectory($Fixture) | Out-Null
try {
    $clean = Join-Path $Fixture 'clean'
    $install = Invoke-Installer -Arguments @('-TargetDir', $clean)
    Assert-Success $install 'clean installation'
    Assert-AllRoles $clean

    $beforeRepeat = Get-DirectorySnapshot $clean
    Assert-Success (Invoke-Installer -Arguments @('-TargetDir', $clean)) 'repeated installation'
    Assert-Equal $beforeRepeat (Get-DirectorySnapshot $clean) 'repeated installation changed the target'

    $beforeCheck = Get-DirectorySnapshot $clean
    Assert-Success (Invoke-Installer -Arguments @('-TargetDir', $clean, '-Check')) 'check mode'
    Assert-Equal $beforeCheck (Get-DirectorySnapshot $clean) 'check mode changed the target'

    $missingCheck = Join-Path $Fixture 'missing-check'
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $missingCheck, '-Check')) 'missing check target'
    if ([IO.Directory]::Exists($missingCheck) -or [IO.File]::Exists($missingCheck)) {
        Fail 'check mode created a missing target'
    }

    $missingRole = Join-Path $Fixture 'missing-role'
    Assert-Success (Invoke-Installer -Arguments @('-TargetDir', $missingRole)) 'missing role fixture installation'
    [IO.File]::Delete((Join-Path $missingRole 'superpowers-astra-reviewer.toml'))
    $beforeMissingRoleCheck = Get-DirectorySnapshot $missingRole
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $missingRole, '-Check')) 'missing role check'
    Assert-Equal $beforeMissingRoleCheck (Get-DirectorySnapshot $missingRole) 'missing role check changed the target'
    Assert-NoStagingFiles $missingRole 'missing role check'

    $modified = Join-Path $Fixture 'modified'
    Assert-Success (Invoke-Installer -Arguments @('-TargetDir', $modified)) 'modified fixture installation'
    [IO.File]::AppendAllText((Join-Path $modified 'superpowers-terra-implementer.toml'), "`nmodified`n")
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $modified)) 'modified destination installation'
    $beforeModifiedCheck = Get-DirectorySnapshot $modified
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $modified, '-Check')) 'modified destination check'
    Assert-Equal $beforeModifiedCheck (Get-DirectorySnapshot $modified) 'modified destination check changed the target'
    Assert-NoStagingFiles $modified 'modified destination rejection'

    $nonRegular = Join-Path $Fixture 'non-regular'
    [IO.Directory]::CreateDirectory($nonRegular) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $nonRegular 'superpowers-luna-implementer.toml')) | Out-Null
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $nonRegular)) 'non-regular destination installation'
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $nonRegular, '-Check')) 'non-regular destination check'
    Assert-NoStagingFiles $nonRegular 'non-regular destination rejection'

    $filesystemRoot = [IO.Path]::GetPathRoot($clean)
    Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $filesystemRoot)) 'filesystem root'

    $codexHome = Join-Path $Fixture 'codex-home'
    $ignoredUserProfile = Join-Path $Fixture 'ignored-user-profile'
    [Environment]::SetEnvironmentVariable('CODEX_HOME', $codexHome, 'Process')
    [Environment]::SetEnvironmentVariable('USERPROFILE', $ignoredUserProfile, 'Process')
    Assert-Success (Invoke-Installer -Arguments @()) 'CODEX_HOME default installation'
    Assert-AllRoles (Join-Path $codexHome 'agents')
    if ([IO.Directory]::Exists((Join-Path $ignoredUserProfile '.codex\agents'))) {
        Fail 'USERPROFILE was used even though CODEX_HOME was set'
    }

    $userProfile = Join-Path $Fixture 'user-profile'
    [Environment]::SetEnvironmentVariable('CODEX_HOME', $null, 'Process')
    [Environment]::SetEnvironmentVariable('USERPROFILE', $userProfile, 'Process')
    Assert-Success (Invoke-Installer -Arguments @()) 'USERPROFILE default installation'
    Assert-AllRoles (Join-Path $userProfile '.codex\agents')

    $racePackage = Join-Path $Fixture 'race-package'
    $raceScripts = Join-Path $racePackage 'scripts'
    $raceAgents = Join-Path $racePackage 'agents'
    [IO.Directory]::CreateDirectory($raceScripts) | Out-Null
    [IO.Directory]::CreateDirectory($raceAgents) | Out-Null
    [IO.File]::Copy($Installer, (Join-Path $raceScripts 'install-codex-agents.ps1'))
    foreach ($role in $RoleNames) {
        [IO.File]::Copy((Join-Path $RepoRoot "agents\$role"), (Join-Path $raceAgents $role))
    }

    $largeTemplate = Join-Path $raceAgents 'superpowers-luna-implementer.toml'
    $largeStream = [IO.File]::Open($largeTemplate, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        [byte[]] $chunk = New-Object byte[] (1024 * 1024)
        for ($chunkIndex = 0; $chunkIndex -lt 32; $chunkIndex++) {
            $largeStream.Write($chunk, 0, $chunk.Length)
        }
    } finally {
        $largeStream.Dispose()
    }

    $raceTarget = Join-Path $Fixture 'race-target'
    [IO.Directory]::CreateDirectory($raceTarget) | Out-Null
    $raceDestination = Join-Path $raceTarget 'superpowers-luna-implementer.toml'
    $raceReady = Join-Path $Fixture 'race-ready'
    [byte[]] $raceMarker = [Text.Encoding]::UTF8.GetBytes('concurrent destination')
    $RaceJob = Start-Job -ScriptBlock {
        param($WatchPath, $DestinationPath, $ReadyPath, [byte[]] $Marker)
        $watcher = New-Object IO.FileSystemWatcher $WatchPath, '.superpowers-agent.*'
        try {
            $watcher.EnableRaisingEvents = $true
            [IO.File]::WriteAllText($ReadyPath, 'ready')
            $change = $watcher.WaitForChanged([IO.WatcherChangeTypes]::Created, 10000)
            if (-not $change.TimedOut) {
                [IO.File]::WriteAllBytes($DestinationPath, $Marker)
            }
        } finally {
            $watcher.Dispose()
        }
    } -ArgumentList $raceTarget, $raceDestination, $raceReady, $raceMarker
    if (-not (Wait-ForPath $raceReady 10000)) {
        Fail 'concurrent destination watcher did not become ready'
    }
    $raceResult = Invoke-Installer -Arguments @('-TargetDir', $raceTarget) -ScriptPath (Join-Path $raceScripts 'install-codex-agents.ps1')
    Assert-Failure $raceResult 'concurrently created destination'
    $null = Wait-Job -Job $RaceJob -Timeout 15
    $null = Receive-Job -Job $RaceJob
    Remove-Job -Job $RaceJob -Force
    $RaceJob = $null
    [byte[]] $actualMarker = [IO.File]::ReadAllBytes($raceDestination)
    Assert-Equal ([Convert]::ToBase64String($raceMarker)) ([Convert]::ToBase64String($actualMarker)) 'concurrent destination was overwritten'
    Assert-NoStagingFiles $raceTarget 'failed no-overwrite move'

    if ($env:OS -ne 'Windows_NT') {
        $symlinkTargetReal = Join-Path $Fixture 'symlink-target-ancestor-real'
        $symlinkTargetLink = Join-Path $Fixture 'symlink-target-ancestor-link'
        [IO.Directory]::CreateDirectory($symlinkTargetReal) | Out-Null
        New-Item -ItemType SymbolicLink -Path $symlinkTargetLink -Target $symlinkTargetReal | Out-Null
        $SymbolicLinks += $symlinkTargetLink

        $symlinkMissingTarget = Join-Path $symlinkTargetLink 'ordinary-missing-child'
        Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $symlinkMissingTarget)) 'symbolic-link ancestor before target creation'
        if ([IO.Directory]::Exists((Join-Path $symlinkTargetReal 'ordinary-missing-child'))) {
            Fail 'installer traversed a symbolic-link ancestor while creating the target'
        }

        $symlinkExistingReal = Join-Path $symlinkTargetReal 'ordinary-existing-child'
        [IO.Directory]::CreateDirectory($symlinkExistingReal) | Out-Null
        $symlinkExistingTarget = Join-Path $symlinkTargetLink 'ordinary-existing-child'
        Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $symlinkExistingTarget)) 'symbolic-link ancestor before destination operations'
        Assert-Equal 0 @([IO.Directory]::GetFiles($symlinkExistingReal)).Count 'installer wrote through a symbolic-link target ancestor'
        Assert-NoStagingFiles $symlinkExistingReal 'symbolic-link target ancestor rejection'

        $symlinkTemplateReal = Join-Path $Fixture 'symlink-template-ancestor-real'
        $symlinkTemplatePackage = Join-Path $symlinkTemplateReal 'ordinary-package'
        $symlinkTemplateScripts = Join-Path $symlinkTemplatePackage 'scripts'
        $symlinkTemplateAgents = Join-Path $symlinkTemplatePackage 'agents'
        [IO.Directory]::CreateDirectory($symlinkTemplateScripts) | Out-Null
        [IO.Directory]::CreateDirectory($symlinkTemplateAgents) | Out-Null
        [IO.File]::Copy($Installer, (Join-Path $symlinkTemplateScripts 'install-codex-agents.ps1'))
        foreach ($role in $RoleNames) {
            [IO.File]::Copy((Join-Path $RepoRoot "agents\$role"), (Join-Path $symlinkTemplateAgents $role))
        }
        $symlinkTemplateLink = Join-Path $Fixture 'symlink-template-ancestor-link'
        New-Item -ItemType SymbolicLink -Path $symlinkTemplateLink -Target $symlinkTemplateReal | Out-Null
        $SymbolicLinks += $symlinkTemplateLink
        $symlinkTemplateTarget = Join-Path $Fixture 'symlink-template-target'
        $symlinkInstaller = Join-Path $symlinkTemplateLink 'ordinary-package\scripts\install-codex-agents.ps1'
        Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $symlinkTemplateTarget) -ScriptPath $symlinkInstaller) 'symbolic-link template ancestor'
        if ([IO.Directory]::Exists($symlinkTemplateTarget)) {
            Fail 'installer created a target after traversing a symbolic-link template ancestor'
        }
    }

    $cmd = Get-Command 'cmd.exe' -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        Write-Output 'SKIP: cmd.exe is unavailable; junction reparse-point tests were not run.'
    } else {
        $realTarget = Join-Path $Fixture 'junction-target-real'
        $junctionTarget = Join-Path $Fixture 'junction-target-link'
        [IO.Directory]::CreateDirectory($realTarget) | Out-Null
        if (-not (New-Junction $junctionTarget $realTarget $cmd.Source)) {
            Write-Output 'SKIP: host refused junction creation; junction reparse-point tests were not run.'
        } else {
            Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $junctionTarget)) 'reparse-point target directory'

            $targetAncestorReal = Join-Path $Fixture 'junction-target-ancestor-real'
            $targetAncestorLink = Join-Path $Fixture 'junction-target-ancestor-link'
            [IO.Directory]::CreateDirectory($targetAncestorReal) | Out-Null
            if (-not (New-Junction $targetAncestorLink $targetAncestorReal $cmd.Source)) {
                Fail 'host created a direct junction but refused the target ancestor junction'
            }
            $missingTargetBelowJunction = Join-Path $targetAncestorLink 'ordinary-missing-child'
            Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $missingTargetBelowJunction)) 'junction ancestor before target creation'
            if ([IO.Directory]::Exists((Join-Path $targetAncestorReal 'ordinary-missing-child'))) {
                Fail 'installer traversed a junction ancestor while creating the target'
            }

            $existingRealBelowJunction = Join-Path $targetAncestorReal 'ordinary-existing-child'
            [IO.Directory]::CreateDirectory($existingRealBelowJunction) | Out-Null
            $existingTargetBelowJunction = Join-Path $targetAncestorLink 'ordinary-existing-child'
            Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $existingTargetBelowJunction)) 'junction ancestor before destination operations'
            Assert-Equal 0 @([IO.Directory]::GetFiles($existingRealBelowJunction)).Count 'installer wrote through a junction target ancestor'
            Assert-NoStagingFiles $existingRealBelowJunction 'junction target ancestor rejection'

            $destinationTarget = Join-Path $Fixture 'junction-destination-target'
            $destinationReal = Join-Path $Fixture 'junction-destination-real'
            [IO.Directory]::CreateDirectory($destinationTarget) | Out-Null
            [IO.Directory]::CreateDirectory($destinationReal) | Out-Null
            $destinationJunction = Join-Path $destinationTarget 'superpowers-luna-implementer.toml'
            if (-not (New-Junction $destinationJunction $destinationReal $cmd.Source)) {
                Fail 'host created one junction but refused the destination junction'
            }
            Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $destinationTarget, '-Check')) 'reparse-point destination'

            $templatePackage = Join-Path $Fixture 'junction-template-package'
            $templateScripts = Join-Path $templatePackage 'scripts'
            [IO.Directory]::CreateDirectory($templateScripts) | Out-Null
            [IO.File]::Copy($Installer, (Join-Path $templateScripts 'install-codex-agents.ps1'))
            $templateJunction = Join-Path $templatePackage 'agents'
            if (-not (New-Junction $templateJunction (Join-Path $RepoRoot 'agents') $cmd.Source)) {
                Fail 'host created one junction but refused the template junction'
            }
            Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', (Join-Path $Fixture 'junction-template-target')) -ScriptPath (Join-Path $templateScripts 'install-codex-agents.ps1')) 'reparse-point template directory'

            $templateAncestorReal = Join-Path $Fixture 'junction-template-ancestor-real'
            $templateAncestorPackage = Join-Path $templateAncestorReal 'ordinary-package'
            $templateAncestorScripts = Join-Path $templateAncestorPackage 'scripts'
            $templateAncestorAgents = Join-Path $templateAncestorPackage 'agents'
            [IO.Directory]::CreateDirectory($templateAncestorScripts) | Out-Null
            [IO.Directory]::CreateDirectory($templateAncestorAgents) | Out-Null
            [IO.File]::Copy($Installer, (Join-Path $templateAncestorScripts 'install-codex-agents.ps1'))
            foreach ($role in $RoleNames) {
                [IO.File]::Copy((Join-Path $RepoRoot "agents\$role"), (Join-Path $templateAncestorAgents $role))
            }
            $templateAncestorLink = Join-Path $Fixture 'junction-template-ancestor-link'
            if (-not (New-Junction $templateAncestorLink $templateAncestorReal $cmd.Source)) {
                Fail 'host created direct junctions but refused the template ancestor junction'
            }
            $templateAncestorTarget = Join-Path $Fixture 'junction-template-ancestor-target'
            $installerBelowTemplateJunction = Join-Path $templateAncestorLink 'ordinary-package\scripts\install-codex-agents.ps1'
            Assert-Failure (Invoke-Installer -Arguments @('-TargetDir', $templateAncestorTarget) -ScriptPath $installerBelowTemplateJunction) 'junction template ancestor'
            if ([IO.Directory]::Exists($templateAncestorTarget)) {
                Fail 'installer created a target after traversing a junction template ancestor'
            }
        }
    }

    Write-Output 'All PowerShell Codex agent installer tests passed.'
} finally {
    [Environment]::SetEnvironmentVariable('CODEX_HOME', $OriginalCodexHome, 'Process')
    [Environment]::SetEnvironmentVariable('USERPROFILE', $OriginalUserProfile, 'Process')
    $cleanupError = $null
    if ($null -ne $RaceJob) {
        Stop-Job -Job $RaceJob -ErrorAction SilentlyContinue
        Remove-Job -Job $RaceJob -Force -ErrorAction SilentlyContinue
    }
    if ($Junctions.Count -ne 0) {
        for ($junctionIndex = $Junctions.Count - 1; $junctionIndex -ge 0; $junctionIndex--) {
            $junction = $Junctions[$junctionIndex]
            if ([IO.Directory]::Exists($junction)) {
                $cmd = Get-Command 'cmd.exe' -ErrorAction SilentlyContinue
                if ($null -eq $cmd) {
                    $cleanupError = "cmd.exe became unavailable while removing junction: $junction"
                    break
                } else {
                    $command = 'rmdir "{0}"' -f $junction
                    $null = & $cmd.Source /d /c $command 2>&1
                    if ($LASTEXITCODE -ne 0 -or [IO.Directory]::Exists($junction)) {
                        $cleanupError = "could not remove junction safely: $junction"
                        break
                    }
                }
            }
        }
    }
    if ($null -eq $cleanupError -and $SymbolicLinks.Count -ne 0) {
        for ($symbolicLinkIndex = $SymbolicLinks.Count - 1; $symbolicLinkIndex -ge 0; $symbolicLinkIndex--) {
            $symbolicLink = $SymbolicLinks[$symbolicLinkIndex]
            if ([IO.Directory]::Exists($symbolicLink) -or [IO.File]::Exists($symbolicLink)) {
                try {
                    Remove-Item -LiteralPath $symbolicLink -Force
                } catch {
                    $cleanupError = "could not remove symbolic link safely '$symbolicLink': $($_.Exception.Message)"
                    break
                }
            }
        }
    }
    if ($null -eq $cleanupError -and [IO.Directory]::Exists($Fixture)) {
        Remove-Item -LiteralPath $Fixture -Recurse -Force
    }
    if ($null -ne $cleanupError) {
        Fail $cleanupError
    }
}
