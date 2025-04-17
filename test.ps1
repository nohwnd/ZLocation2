param (
    [switch] $CI
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module Pester -ListAvailable)) {
    Install-Module Pester -Scope CurrentUser
}

$env:ZLOCATION_TEST = 1
Remove-Item $PSScriptRoot/testdb.db -ErrorAction Ignore

Get-Module ZLocation2 | Remove-Module

Import-Module $PSScriptRoot/ZLocation2/ZLocation2.psd1

$configuration = New-PesterConfiguration
$configuration.Output.Verbosity = 'Detailed'

if ($CI) {
    $configuration.Run.Exit = $true
    $configuration.TestResult.Enabled = $true
}

Invoke-Pester -Configuration $configuration