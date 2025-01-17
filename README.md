ZLocation2
=========

ZLocation2 is an opinionated fork of ZLocation [ZLocation](https://github.com/vors/zlocation).

Tracks your most used directories, based on number of previously run commands.
After  a  short  learning  phase, `z` will take you to the most popular directory that matches all of the regular expressions given on the command line.
You can use **Tab-Completion / Intellisense** to pick directories that are not the first choice.

Usage
-----

ZLocation keeps track of your `$pwd` (current folder).
Once visited, folder become known to ZLocation.
You can `cd` with just a hint of the path!

The full command name is `Invoke-ZLocation`, but in examples I use alias `z`.
It's all about navigation speed, isn't it?

```
PS C:\Users\sevoroby> z c:
PS C:\> z zlo
PS C:\dev\ZLocation> z dsc
PS C:\dev\azure-sdk-tools\src\ServiceManagement\Compute\Commands.ServiceManagement\IaaS\Extensions\DSC> z test
PS C:\dev\ZLocation\ZLocation.Tests>
```

### List known locations

`z` without arguments will list all the known locations and their weights (short-cut for `Get-ZLocation`)

To see all locations matched to a query `foo` use `z -l foo`.

### Navigating to less common directories with tab completion

If `z mydir` doesn't take you to the correct directory, you can also tab through
ZLocation's suggestions.

For example, pressing tab with `z src` will take you through all of ZLocation's
completions for `src`.

### Going back

ZLocation keeps a stack of directories as you jump between them. `z -` will
"pop" the stack: it will move you to the previous directory you jumped to,
basically letting you undo your `z` navigation.

If the stack is empty (you have only jumped once), `z -` will take you to your
original directory.

For example:

```ps
C:\>z foo
C:\foo>z bar
C:\baz\bar> z -
C:\foo>z -
C:\>z -
C:\>#no-op
```

### Custom database file location

ZLocation uses a database file to store the list of known directories. By default, it is located at `$HOME\z-location2.db`. If you want to use a custom path, set the `$env:ZLOCATION_DATABASE_PATH` to full path to the database (e.g. `C:\temp\my.db`) before importing the module.

Goals / Key features
--------------------

*  Support for multiple PS sessions.
*  Good built-in ranking algorithm.
*  ~~Customizable matching algorithm and weight function.~~
*  Works on Windows, Linux and MacOS.

## Install
Install from [PowerShellGet Gallery](https://www.powershellgallery.com/packages/ZLocation2/)

```powershell
Install-Module ZLocation2
```

Make sure to **include ZLocation import in your `$PROFILE`**.
It intentionally doesn't alter `$PROFILE` automatically on installation.

This one-liner installs ZLocation, imports it and adds it to a profile.

```powershell
Install-Module ZLocation2 -Scope CurrentUser; Import-Module ZLocation2; Add-Content -Value "`r`n`r`nImport-Module ZLocation2`r`n" -Encoding utf8 -Path $PROFILE.CurrentUserAllHosts
```

If you want to display some additional information about ZLocation on start-up, you can put this snippet in `$PROFILE` after import. 
```powershell
Write-Host -Foreground Green "`n[ZLocation] knows about $((Get-ZLocation).Keys.Count) locations.`n"
```

### Note

ZLocation alters your prompt function to track the location. Meaning if you use this module with other modules that modifies your prompt function (e.g. such as `posh-git`), then you'd need to adjust your [Powershell profile file](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7). The statement `Import-Module ZLocation` needs to be placed **after** the other module imports that modifies your prompt function.

You can open up `profile.ps1` through using any of the below commands:

```powershell
notepad $PROFILE.CurrentUserAllHosts
notepad $env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1
notepad $Home\Documents\WindowsPowerShell\profile.ps1
```

Alternatively, type up the below in your file explorer, and then edit the `profile.ps1` file with an editor of your choice:

```
%USERPROFILE%\Documents\WindowsPowerShell
```

License
-------

ZLocation2 is released under the [MIT](LICENSE) license.

ZLocation2 bundles a copy of LiteDB - [MIT license](https://github.com/litedb-org/LiteDB/blob/master/LICENSE)
ZLocation2 is a fork of ZLocation - [MIT license](https://github.com/vors/ZLocation/blob/master/LICENSE)

Develop
-------

### Run tests

Run ./test.ps1

The module modifies your prompt, so expect problems when you debug. It also has hard time handling when ZLocation (the original one) or ZLocation2 (the new one) are installed. Looking into this.
