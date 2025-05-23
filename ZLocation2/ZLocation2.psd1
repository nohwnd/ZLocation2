@{

# Script module or binary module file associated with this manifest.
RootModule = 'ZLocation2.psm1'

# Version number of this module.
ModuleVersion = '2.2.0'

# ID used to uniquely identify this module
GUID = 'd3f9bef0-6194-420b-a4fa-5fea681d9fa0'

# Author of this module
Author = 'nohwnd'

# Copyright statement for this module
Copyright = '(c) 2025 nohwnd. All rights reserved.'

# Description of the functionality provided by this module
Description = 'ZLocation2 is the new Zlocation. A `cd` that learns.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @("LiteDB\System.Buffers.dll", "LiteDB\LiteDB.dll")

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# This creates additional scopes and Pester cannot mock cmdlets in those scopes. We use Import-Module directly in Zlocation.psm1 instead.
NestedModules = @()

# Functions to export from this module
FunctionsToExport = @(
    'Get-ZLocation',
    'Invoke-ZLocation',
    'Pop-ZLocation',
    'Remove-ZLocation',
    'Set-ZLocation',
    'Update-ZLocation',
    'Clear-NonExistentZLocation'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @(
    'z'
)

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('cd', 'productivity')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/nohwnd/ZLocation2/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/nohwnd/ZLocation2'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'https://github.com/nohwnd/ZLocation2/releases/tag/2.2.0'

        # Prerelease string of this module
        Prerelease   = 'rc2'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
