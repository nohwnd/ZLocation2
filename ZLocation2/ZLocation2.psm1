Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\LiteDB.ps1"
. "$PSScriptRoot\Service.ps1"
. "$PSScriptRoot\Search.ps1"
. "$PSScriptRoot\Storage.ps1"

# I currently consider number of commands executed in directory to be a better metric, than total time spent in a directory.
# See [corresponding issue](https://github.com/vors/ZLocation/issues/6) for details.
# If you prefer the old behavior, uncomment this code.
<#
#
# Weight function.
#
function Update-ZLocation([string]$path)
{
    $now = [datetime]::Now
    if (Test-Path variable:global:__zlocation_current)
    {
        $prev = $global:__zlocation_current
        $weight = $now.Subtract($prev.Time).TotalSeconds
        Add-ZWeight ($prev.Location) $weight
    }

    $global:__zlocation_current = @{
        Location = $path
        Time = [datetime]::Now
    }

    # populate folder immediately after the first cd
    Add-ZWeight $path 0
}

# this approach hurts `cd` performance (0.0008 sec vs 0.025 sec).
# Consider replacing it with OnIdle Event.
(Get-Variable pwd).attributes.Add((new-object ValidateScript { Update-ZLocation $_.Path; return $true }))
#>

function Update-ZLocation
{
    param (
        [Parameter(Mandatory=$true)] [string]$Path
    )
    Add-ZWeight $Path 1.0
}

function Register-PromptHook
{
    param()

    # Insert a call to Update-Zlocation in the prompt function but only once.
    if (-not (Test-Path function:\global:ZlocationOrigPrompt)) {
        Copy-Item function:\prompt function:\global:ZlocationOrigPrompt
        $global:ZLocationPromptScriptBlock = {
            ZLocationOrigPrompt
            Update-ZLocation $pwd
        }

        Set-Content -Path function:\prompt -Value $global:ZLocationPromptScriptBlock -Force
    }
}

#
# End of weight function.
#


#
# Tab completion.
#
if(Get-Command -Name Register-ArgumentCompleter -ErrorAction Ignore) {
    'Set-ZLocation', 'Invoke-ZLocation' | % {
        Register-ArgumentCompleter -CommandName $_ -ParameterName match -ScriptBlock {
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            # Omit first item (command name) and empty strings
            $i = $commandAst.CommandElements.Count
            [string[]]$query = if($i -gt 1) {
                $commandAst.CommandElements[1..($i-1)] | ForEach-Object { $_.toString()}
            }
            
            (Find-Matches (Get-ZLocationUnsorted) $query).Path | Get-EscapedPath
        }
    }
}

function Get-EscapedPath
{
    param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [string]$path
    )

    process {
        if ($path.Contains(' '))
        {
            return '"' + $path + '"'
        }
        return $path
    }
}

#
# End of tab completion.
#

# Default location stack is local for module. Users cannot use 'Pop-Location' directly, so we need to provide a command inside the module for that.
function Pop-ZLocation
{
    Pop-Location
}

function Set-ZLocation([Parameter(ValueFromRemainingArguments)][string[]]$match)
{
    Register-PromptHook

    if (-not $match) {
        $match = @()
    }

    # Special case to enable Pop-Location.
    if (($match.Count -eq 1) -and ($match[0] -eq '-')) {
        Pop-ZLocation
        return
    }

    $found = Find-Matches (Get-ZLocationUnsorted) $match
    $pushDone = $false
    foreach ($m in $found) {
        if (Test-Path $m.Path) {
            Push-Location $m.Path
            $pushDone = $true
            break
        } else {
            Write-Warning "There is no path $($m.Path) on the file system. Removing obsolete data from database."
            Remove-ZLocation $m
        }
    }
    if (-not $pushDone) {
        if (($found.Count -eq 1) -and (Test-Path $found.Path)) {
            Write-Debug "No matches for $($match.Path), attempting Push-Location"
            Push-Location "$match"
        } else {
            Write-Warning "Cannot find matching location"
        }
    }
}

<#
    .SYNOPSIS
    Jump or show popular directories.

    .DESCRIPTION
    This is the main entry point in the interactive usage of ZLocation.
    
    It's intended to be used as an alias z, and serves 3 purposes:
    1. Jump to a directory that matches the given query
        EXAMPLE:
            PS> z proj
            PS C:\source\projects> 

    2. Jump to most recently visited directory.
        EXAMPLE:
            PS C:\Users\nohwnd> z -
            PS C:\source\projects>

    3. Show the most popular directories.
        EXAMPLE:
            PS> z
            Path                      Weight
            ----                      ------
            C:\source\projects\Pester 8045
            C:\source\projects        472
            C:\movies\StarWars        123

   .EXAMPLE
    PS> z proj
    PS C:\source\projects> 

   .EXAMPLE
    PS C:\Users\nohwnd> z -
    PS C:\source\projects>

    .EXAMPLE
    PS> z
    Path                      Weight
    ----                      ------
    C:\source\projects\Pester 8045
    C:\source\projects        472
    C:\movies\StarWars        123

    .EXAMPLE
    C:\>z foo <PRESS TAB; NOT ENTER>
    C:\>z C:\foo <PRESS TAB AGAIN>
    C:\>z C:\another_less_popular\foo <PRESS TAB AGAIN>
    C:\>z C:\least_popular\foo
    C:\least_popular\foo>


    .LINK
    https://github.com/nohwnd/ZLocation2
#>
function Invoke-ZLocation
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory,ParameterSetName='GetFilteredPopularPaths')]
        [Alias('l')]
        [string[]]$Location,
        [Parameter(ValueFromRemainingArguments,ParameterSetName='Default')][string[]]$Match
    )


    $locations = $null
    
    # We queried the database for locations, and we will return them sorted.
    # This implements scenario 3.
    if ($PSCmdlet.ParameterSetName -eq 'GetFilteredPopularPaths') {
        return Get-ZLocation -Match $Location
    }
    else {
        if ($null -eq $Match -or $Match.Count -eq 0) {    
            return Get-ZLocation
        }
    }


    # This implements scenario 1 and 2, if we did not return before.
    Set-ZLocation -Match $match
}

function Get-FrequentFolders {
    If (((Get-Variable IsWindows -ErrorAction Ignore | Select-Object -ExpandProperty Value) -or 
    $PSVersionTable.PSVersion.Major -lt 6) -and ([environment]::OSVersion.Version.Major -ge 10)) {
        if (-not $ExecutionContext.SessionState.LanguageMode -eq 'ConstrainedLanguage') {
            $QuickAccess = New-Object -ComObject shell.application
            $QuickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items() |
                Where-Object IsFolder |
                Select-Object -ExpandProperty Path
        }
    }
}

function Clear-NonExistentZLocation {
    $paths = (Get-ZLocation).Path
    foreach ($path in $paths)
    {
        if (!(Test-Path $path)) {
            Remove-ZLocation $path
            Write-Host $path "removed from ZLocation"
        }
    }
}

# Get-FrequentFolders | ForEach-Object {
#     if (Test-Path $_) {
#         Add-ZWeight -Path $_ -Weight 0
#     }
# }

# On removal/unload of the module, restore original prompt or LocationChangedAction event handler.
$ExecutionContext.SessionState.Module.OnRemove = {
    Write-Host "Removing prompt."
    Copy-Item function:\global:ZlocationOrigPrompt function:\global:prompt
    Remove-Item function:\ZlocationOrigPrompt
    Remove-Variable ZLocationPromptScriptBlock -Scope Global
}

Register-PromptHook

Set-Alias -Name z -Value Invoke-ZLocation

Export-ModuleMember -Function @('Invoke-ZLocation', 'Set-ZLocation', 'Get-ZLocation', 'Pop-ZLocation', 'Remove-ZLocation', 'Clear-NonexistentZLocation') -Alias z
# export this function to make it accessible from prompt
Export-ModuleMember -Function Update-ZLocation
