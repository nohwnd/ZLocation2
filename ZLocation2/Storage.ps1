function Get-ZLocationUnsorted ($Match) {
    $service = Get-ZService
    $entries =  $service.Get()
    if (-not $Match) {
        return $entries
    }
    
    foreach ($match in $Match) {
        foreach ($found in (Find-Matches $entries $match)) {
            $found
        }
    }
}

function Get-ZLocation
{
    [CmdletBinding()]
    param (
        [string[]] $Match,
        [ValidateSet("Weight", "LastUsed", "Path")]
        [string] $Sort = "Weight"
    )

    Get-ZLocationUnsorted -Match $Match | Sort-Object -Property $Sort -Descending
}

function Add-ZWeight {
    param (
        [Parameter(Mandatory=$true)] [string]$Path,
        [Parameter(Mandatory=$true)] [double]$Weight
    )
    $service = Get-ZService
    $service.Add($path, $weight)
}

function Remove-ZLocation {
    param (
        [Parameter(Mandatory=$true)] [string]$Path
    )
    $service = Get-ZService
    $service.Remove($path)
}