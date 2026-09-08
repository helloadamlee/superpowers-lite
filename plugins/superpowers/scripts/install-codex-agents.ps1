[CmdletBinding()]
param(
    [Parameter()][string] $TargetDir,
    [Parameter()][switch] $Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail([string] $Message) {
    [Console]::Error.WriteLine("ERROR: $Message")
    exit 1
}

function Test-ReparsePoint([string] $LiteralPath) {
    $item = Get-Item -LiteralPath $LiteralPath -Force
    return (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Test-SameFile([string] $Left, [string] $Right) {
    Assert-NoReparsePointInExistingPath $Left 'comparison path'
    Assert-NoReparsePointInExistingPath $Right 'comparison path'
    [byte[]] $leftBytes = [IO.File]::ReadAllBytes($Left)
    [byte[]] $rightBytes = [IO.File]::ReadAllBytes($Right)
    if ($leftBytes.Length -ne $rightBytes.Length) {
        return $false
    }
    for ($index = 0; $index -lt $leftBytes.Length; $index++) {
        if ($leftBytes[$index] -ne $rightBytes[$index]) {
            return $false
        }
    }
    return $true
}

function Get-AbsolutePath([string] $LiteralPath) {
    if ([string]::IsNullOrWhiteSpace($LiteralPath)) {
        Fail 'path must not be empty'
    }
    try {
        return [IO.Path]::GetFullPath($LiteralPath)
    } catch {
        Fail "invalid path '$LiteralPath': $($_.Exception.Message)"
    }
}

function Get-PathItem([string] $LiteralPath) {
    try {
        return Get-Item -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue
    } catch {
        Fail "could not inspect path '$LiteralPath': $($_.Exception.Message)"
    }
}

function Get-ReparsePointInExistingPath([string] $LiteralPath) {
    $absolutePath = Get-AbsolutePath $LiteralPath
    $pathRoot = [IO.Path]::GetPathRoot($absolutePath)
    if ([string]::IsNullOrWhiteSpace($pathRoot)) {
        Fail "path has no filesystem root: $absolutePath"
    }

    $currentPath = $pathRoot
    $currentItem = Get-PathItem $currentPath
    if ($null -eq $currentItem) {
        return $null
    }
    if (($currentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        return $currentPath
    }

    $remainingPath = $absolutePath.Substring($pathRoot.Length)
    [char[]] $separators = @([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    [string[]] $components = $remainingPath.Split($separators, [StringSplitOptions]::RemoveEmptyEntries)
    foreach ($component in $components) {
        $currentPath = [IO.Path]::Combine($currentPath, $component)
        $currentItem = Get-PathItem $currentPath
        if ($null -eq $currentItem) {
            return $null
        }
        if (($currentItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            return $currentPath
        }
    }
    return $null
}

function Assert-NoReparsePointInExistingPath([string] $LiteralPath, [string] $Description) {
    $reparsePoint = Get-ReparsePointInExistingPath $LiteralPath
    if ($null -ne $reparsePoint) {
        Fail "$Description traverses a reparse point: $reparsePoint"
    }
}

function Assert-SafeDirectory([string] $LiteralPath, [string] $Description) {
    Assert-NoReparsePointInExistingPath $LiteralPath $Description
    $item = Get-PathItem $LiteralPath
    if ($null -eq $item -or -not ($item -is [IO.DirectoryInfo])) {
        Fail "$Description is not a directory: $LiteralPath"
    }
    if (Test-ReparsePoint $LiteralPath) {
        Fail "$Description is a reparse point: $LiteralPath"
    }
}

function Assert-SafeFile([string] $LiteralPath, [string] $Description) {
    Assert-NoReparsePointInExistingPath $LiteralPath $Description
    $item = Get-PathItem $LiteralPath
    if ($null -eq $item) {
        Fail "$Description is missing: $LiteralPath"
    }
    if (Test-ReparsePoint $LiteralPath) {
        Fail "$Description is a reparse point: $LiteralPath"
    }
    if (-not ($item -is [IO.FileInfo])) {
        Fail "$Description is not a regular file: $LiteralPath"
    }
}

$RoleNames = @(
    'superpowers-luna-implementer.toml',
    'superpowers-terra-implementer.toml',
    'superpowers-astra-implementer.toml',
    'superpowers-astra-reviewer.toml'
)

if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $TargetDir = Join-Path $env:CODEX_HOME 'agents'
    } else {
        $userProfile = $env:USERPROFILE
        if ([string]::IsNullOrWhiteSpace($userProfile)) {
            $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        }
        if ([string]::IsNullOrWhiteSpace($userProfile)) {
            Fail 'USERPROFILE or CODEX_HOME must be set, or pass -TargetDir'
        }
        $TargetDir = Join-Path (Join-Path $userProfile '.codex') 'agents'
    }
}

$TargetDir = Get-AbsolutePath $TargetDir
$targetRoot = Get-AbsolutePath ([IO.Path]::GetPathRoot($TargetDir))
[char[]] $directorySeparators = @([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$normalizedTarget = $TargetDir.TrimEnd($directorySeparators)
$normalizedRoot = $targetRoot.TrimEnd($directorySeparators)
if ([string]::Equals($normalizedTarget, $normalizedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    Fail "refusing to use filesystem root: $TargetDir"
}

$TemplateDir = Get-AbsolutePath (Join-Path $PSScriptRoot '..\agents')
Assert-SafeDirectory $TemplateDir 'template directory'

Assert-NoReparsePointInExistingPath $TargetDir 'target directory'
$targetItem = Get-PathItem $TargetDir
if ($null -ne $targetItem) {
    Assert-SafeDirectory $TargetDir 'target directory'
} elseif ($Check) {
    Fail "target directory is missing: $TargetDir"
} else {
    try {
        Assert-NoReparsePointInExistingPath $TargetDir 'target directory'
        [IO.Directory]::CreateDirectory($TargetDir) | Out-Null
    } catch {
        Fail "could not create target directory '$TargetDir': $($_.Exception.Message)"
    }
    Assert-SafeDirectory $TargetDir 'target directory'
}

foreach ($role in $RoleNames) {
    $template = Join-Path $TemplateDir $role
    $destination = Join-Path $TargetDir $role
    Assert-SafeDirectory $TargetDir 'target directory'
    Assert-SafeFile $template 'shipped template'

    Assert-NoReparsePointInExistingPath $destination 'destination'
    $destinationItem = Get-PathItem $destination
    if ($null -ne $destinationItem) {
        Assert-SafeFile $template 'shipped template'
        Assert-SafeFile $destination 'destination'
        if (-not (Test-SameFile $template $destination)) {
            if ($Check) {
                Fail "role differs from template: $destination"
            }
            Fail "refusing modified destination: $destination"
        }
        continue
    }

    if ($Check) {
        Fail "missing role: $destination"
    }

    $staged = Join-Path $TargetDir ('.superpowers-agent.' + [Guid]::NewGuid().ToString('N') + '.tmp')
    $installError = $null
    $cleanupError = $null
    try {
        Assert-SafeDirectory $TargetDir 'target directory'
        Assert-SafeFile $template 'shipped template'
        Assert-NoReparsePointInExistingPath $staged 'staging path'
        [IO.File]::Copy($template, $staged, $false)
        Assert-SafeDirectory $TargetDir 'target directory'
        Assert-SafeFile $staged 'staging file'
        Assert-NoReparsePointInExistingPath $destination 'destination'
        [IO.File]::Move($staged, $destination)
    } catch {
        $installError = $_.Exception.Message
    } finally {
        try {
            $cleanupReparsePoint = Get-ReparsePointInExistingPath $staged
            if ($null -ne $cleanupReparsePoint) {
                $cleanupError = "refusing to traverse reparse point '$cleanupReparsePoint'"
            } elseif ([IO.File]::Exists($staged)) {
                [IO.File]::Delete($staged)
            }
        } catch {
            $cleanupError = $_.Exception.Message
        }
    }

    if ($null -ne $cleanupError) {
        Fail "could not remove staging file '$staged': $cleanupError"
    }
    if ($null -ne $installError) {
        Fail "could not install '$destination' without overwrite: $installError"
    }
    [Console]::Out.WriteLine("INSTALLED: $destination")
}

if ($Check) {
    [Console]::Out.WriteLine('CHECK PASSED: all Codex roles match their templates')
} else {
    [Console]::Out.WriteLine('INSTALLATION COMPLETE: Codex roles are ready')
}
