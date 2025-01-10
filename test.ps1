Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module Pester -ListAvailable)) {
    Install-Module Pester
}

$env:ZLOCATION_TEST = 1
Remove-Item $PSScriptRoot/testdb.db -ErrorAction Ignore

Get-Module ZLocation2 | Remove-Module

try {
    Import-Module $PSScriptRoot/ZLocation2/ZLocation2.psd1
    Invoke-Pester -Output Detailed
}
finally {
    Get-Module ZLocation2 | Remove-Module
}