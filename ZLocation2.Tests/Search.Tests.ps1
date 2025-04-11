Describe 'Find-Matches filters results correctly' {
    BeforeDiscovery {
        if(-not (Test-Path -Path Variable:IsWindows)) {
            $script:IsWindows = $true
        }
    }
    BeforeAll {
        $zlocationModule = Get-Module ZLocation2
        ${function:Find-Matches} = & $zlocationModule { Get-Command Find-Matches -Module ZLocation2 } 

        function ConvertTo-LocationArray {
            param (
                [Parameter(ValueFromPipeline,Mandatory)] 
                [hashtable]$Hash
            )
            foreach ($item in $Hash.GetEnumerator()) {
                & $zlocationModule {
                    param($item)
                    New-Object -TypeName Location -Property @{
                        path = $item.Key
                        weight = $item.Value
                    }
                } $item
            }
        }
        
    }

    Context 'Equal weight' {
        BeforeAll {
            if($IsWindows) {
                $data = @{
                    'C:\foo1\foo2\foo3' = 1.0
                    'C:\foo1\foo2' = 1.0
                    'C:\foo1' = 1.0
                    'C:\' = 1.0
                } | ConvertTo-LocationArray
                $rootPath = 'C:\'
                $foo1Path = 'C:\foo1'
                $foo2Path = 'C:\foo1\foo2'
                $foo3Path = 'C:\foo1\foo2\foo3'
                $pathSep = '\'
            } else {
                $data = @{
                    '/foo1/foo2/foo3' = 1.0
                    '/foo1/foo2' = 1.0
                    '/foo1' = 1.0
                    '/' = 1.0
                } | ConvertTo-LocationArray
                $rootPath = '/'
                $foo1Path = '/foo1'
                $foo2Path = '/foo1/foo2'
                $foo3Path = '/foo1/foo2/foo3'
                $pathSep = '/'
            }
        }

        It 'returns only filtered results' {
            (Find-Matches $data foo2).Path | Should -Be $foo2Path
        }

        It 'returns multiply results' {
            (Find-Matches $data foo | Measure-Object).Count | Should -Be 3
        }

        It 'should be case-insensitive' {
            (Find-Matches $data FoO1).Path | Should -Be $foo1Path
        }

        If($IsWindows) {
            It 'returns disk root folder for C:' {
                (Find-Matches $data C:).Path | Should -Be $rootPath
            }

            It 'returns disk root folder for C' {
                (Find-Matches $data C).Path | Should -Be $rootPath
            }
        } else {
            It 'returns disk root folder for /' {
                (Find-Matches $data /).Path | Should -Be $rootPath
            }
        }

        It "should ignore trailing <pathSep>" {
            (Find-Matches $data "$foo1Path$pathSep").Path | Should -Be $foo1Path
        }

    }

    Context 'Different weight' {

        BeforeAll {
            if($IsWindows) {
                $data = @{
                    'C:\admin' = 1.0
                    'C:\admin\monad' = 2.0
                } | ConvertTo-LocationArray
                $adminPath = 'C:\admin'
            } else {
                $data = @{
                    '/admin' = 1.0
                    '/admin/monad' = 2.0
                } | ConvertTo-LocationArray
                $adminPath = '/admin'
            }
        }

        It 'Uses leaf match' {
            (Find-Matches $data 'adm').Path | Should -Be $adminPath
        }
    }

    Context 'Prefer prefix over weight' {
        BeforeAll {
            if($IsWindows) {
                $fooPath = 'C:\foo'
                $afooPath = 'C:\afoo'
            } else {
                $fooPath = '/foo'
                $afooPath = '/afoo'
            }
            $data = @{
                $fooPath = 1.0
                $afooPath = 1000.0
            } | ConvertTo-LocationArray
        }

        It 'Uses prefix match' {
            (Find-Matches $data 'fo').Path | Should -Be @($fooPath, $afooPath)
        }
    }

    Context 'Prefer exact match over weight and prefix' {
        BeforeAll {
            if($IsWindows) {
                $fooPath = 'C:\foo'
                $afooPath = 'C:\foo2'
            } else {
                $fooPath = '/foo'
                $afooPath = '/foo2'
            }
            $data = @{
                $fooPath = 1.0
                $afooPath = 1000.0
            } | ConvertTo-LocationArray
        }

        It 'Uses prefix match' {
            (Find-Matches $data 'foo').Path | Should -Be @($fooPath, $afooPath)
        }
    }
}