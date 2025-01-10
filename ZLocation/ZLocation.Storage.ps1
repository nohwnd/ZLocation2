function Get-ZLocation($Match)
{
    $service = Get-ZService
    $hash = [Collections.HashTable]::new()
    foreach ($item in $service.Get())
    {
        $hash[$item.path] = $item.weight
    }

    if ($Match)
    {
        # Create a new hash containing only matching locations
        $newhash = @{}
        $Match | %{Find-Matches $hash $_} | %{$newhash.add($_, $hash[$_])}
        $hash = $newhash
    }

    return $hash
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