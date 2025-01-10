$env:ZLOCATION_TEST = 1
Get-Module ZLocation | Remove-Module
Import-Module $PSScriptRoot/ZLocation/ZLocation.psd1

Invoke-Pester