[CmdletBinding()]
param(
    [Parameter(Position = 0)][string] $ModelTier,
    [Parameter(ValueFromRemainingArguments = $true)][string[]] $RemainingArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ModelTier) -or ($null -ne $RemainingArguments -and $RemainingArguments.Count -ne 0)) {
    [Console]::Error.WriteLine('ERROR: exactly one modelTier is required')
    exit 2
}

switch -CaseSensitive ($ModelTier) {
    'mechanical' { $Role = 'superpowers_luna_implementer' }
    'standard' { $Role = 'superpowers_terra_implementer' }
    'frontier' { $Role = 'superpowers_astra_implementer' }
    'review' { $Role = 'superpowers_astra_reviewer' }
    default {
        [Console]::Error.WriteLine("ERROR: unknown modelTier: $ModelTier")
        exit 2
    }
}

[Console]::Out.WriteLine($Role)
