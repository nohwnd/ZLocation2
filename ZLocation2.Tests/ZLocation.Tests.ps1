# Integration tests.

Describe 'ZLocation' {
    BeforeEach {
        # Clear the ZLocation2 test database
        Remove-Item $PSScriptRoot/../testdb.db -ErrorAction Ignore
    }

    Context 'Success scenario' {

        It 'can execute scenario with new directory' {
            $originalPath = $pwd
            try {
                $testDrive = (Get-PSDrive -Name 'TestDrive').Root
                
                $newDirectory = mkdir "$testDrive/newDirectory"
                cd "$testDrive/newDirectory"

                # trigger weight update
                prompt > $null
                
                # go back
                cd $testDrive

                # jump to the new directory
                z "new"

                $pwd | Should -Be (Join-Path $testDrive "newDirectory")

                # verify that pop-location can be used after z
                z -
                $pwd | Should -Be $testDrive

                (Get-ZLocation -Match $newDirectory).Weight | Should -Be 1
            } finally {
                cd $originalPath
                Remove-Item -Recurse -force "$testDrive/newDirectory"
                Remove-ZLocation "$testDrive/newDirectory"
            }
        }
    }

    Context 'tab completion' {
        BeforeAll {
            function Complete($command) {
                [System.Management.Automation.CommandCompletion]::CompleteInput($command, $command.Length, @{}).CompletionMatches.ListItemText
                (TabExpansion2 $command $command.Length).CompletionMatches.ListItemText
            }
        }
        BeforeEach {
            Update-ZLocation 'prefixABC'
            Update-ZLocation 'prefixDEF'
            Update-ZLocation 'notthisGHI'
            Update-ZLocation 'notthisJKL'
        }
        AfterEach {
            Remove-ZLocation -path 'prefixABC'
            Remove-ZLocation -path 'prefixDEF'
            Remove-ZLocation -path 'notthisGHI'
            Remove-ZLocation -path 'notthisJKL'
        }
        It 'should offer only completions matching entered text' {
            $completions = Complete 'z refix'
            $completions | Should -Contain 'prefixABC'
            $completions | Should -Contain 'prefixDEF'
            $completions | Should -Not -Contain 'notthisGHI'
            $completions | Should -Not -Contain 'notthisJKL'
        }
        It 'should offer all completions when invoked without prefix' {
            $completions = Complete 'z '
            $completions | Should -Contain 'prefixABC'
            $completions | Should -Contain 'prefixDEF'
            $completions | Should -Contain 'notthisGHI'
            $completions | Should -Contain 'notthisJKL'
        }
    }


    Context "Getting latest entries in zlocation table" {
        It "should return the latest entries in zlocation table" {
            # will insert it initially
            Update-ZLocation 'latest'

            # we then access this path to be newest and have the highest weight
            Update-ZLocation 'old'
            Update-ZLocation 'old'
            Update-ZLocation 'old'
            Update-ZLocation 'old'

            Start-Sleep -Seconds 1

            # then we access latest again, and it should be on top of the list when asking for latest
            # but not have the highest weight
            $now = (Get-Date)
            # the DB will cut off any time that is smaller than milliseconds, so we round up to whole second
            # because after truncating the now in db might be before the $now in code.
            $nowTrimmed = Get-Date -Date $now -Millisecond 0
            Update-ZLocation 'latest'

            # check the default sort by weight, old should be on top
            $latest = Get-ZLocation
            $latest.Path | Should -Be 'old', 'latest'

            # now sort by last used, and latest should be on top
            $latest = Get-ZLocation -Sort 'LastUsed'
            $latest.Path | Should -Be 'latest', 'old'
        
            # check timing on last used is recent (and is not UTC)
            $latestEntry = $latest[0]
            $latestEntry.Path | Should -Be 'latest'
            $latestEntry.LastUsed | Should -BeGreaterThan $nowTrimmed # is not too old
            $latestEntry.LastUsed | Should -BeLessThan $nowTrimmed.AddSeconds(1) # is not too new
        }
    }

    Context "Warnings and debug." {
        
        BeforeEach {
            $container = @{ Warning = @(); Debug = @() }
            Mock Write-Warning { 
                $container.Warning += $message
            } -ModuleName ZLocation2

            Mock Write-Debug { 
                $container.Debug += $message
            } -ModuleName ZLocation2
        }

        It "When location is found in db, and is not on disk, warning is shown, and the location is removed from db" {

            $testDrive = (Get-PSDrive -Name 'TestDrive').Root
            $newDirectory = mkdir "$testDrive/will-delete-directory"
            Invoke-ZLocation $newDirectory
            # trigger prompt as cmdline would do it when we navigate to new directory
            prompt > $null

            Set-Location $testDrive
            # remove the directory from disk, but keep in db
            Remove-Item -Recurse -Force $newDirectory

            Invoke-ZLocation $newDirectory

            $container.Warning[0] | Should -BeLike 'There is no path *will-delete-directory on the file system. Removing obsolete data from database.'
            $container.Warning[1] | Should -BeLike "Cannot find matching location for '*will-delete-directory'."
        }

        It "When location is not found in db, and is not on disk, warning is shown" {

            Set-ZLocation 'non-existing-directory'

            $container.Warning | Should -Be "Cannot find matching location for 'non-existing-directory'."
        }

        It "When location is not found in db, and it is present on disk, debug is written and we go to the location" {

            $testDrive = (Get-PSDrive -Name 'TestDrive').Root
            $newDirectory = mkdir "$testDrive/existing-directory"
            Set-ZLocation $newDirectory

            $container.Debug | Should -BeLike "No matches for '*\existing-directory', attempting Push-Location."

           "$PWD" | Should -Be "$newDirectory"
        }
    }
}
