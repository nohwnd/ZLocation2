Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$env:ZLOCATION_TEST = 1
Remove-Item $PSScriptRoot/testdb.db -ErrorAction Ignore

Get-Module ZLocation | Remove-Module

try {
    Import-Module $PSScriptRoot/ZLocation/ZLocation.psd1
    Invoke-Pester -Output Detailed
}
finally {
    Get-Module ZLocation | Remove-Module
}