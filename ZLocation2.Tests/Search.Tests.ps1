Describe 'Find-Matches filters results correctly' {
    BeforeAll {
        ${function:Find-Matches} = & (Get-Module ZLocation2) { Get-Command Find-Matches -Module ZLocation2 } 
    }

    Context 'Equal weight on <os>' -ForEach @(
        @{
            os = 'Windows'
            data = @{
                'C:\foo1\foo2\foo3' = 1.0
                'C:\foo1\foo2' = 1.0
                'C:\foo1' = 1.0
                'C:\' = 1.0
            }
            rootQuery = 'C'
            rootPath = 'C:\'
            foo1Path = 'C:\foo1'
            foo2Path = 'C:\foo1\foo2'
            foo3Path = 'C:\foo1\foo2\foo3'
        }
        @{
            os = 'Linux'
            data = @{
                '/foo1/foo2/foo3' = 1.0
                '/foo1/foo2' = 1.0
                '/foo1' = 1.0
                '/' = 1.0
            }
            rootQuery = '/'
            rootPath = '/'
            foo1Path = '/foo1'
            foo2Path = '/foo1/foo2'
            foo3Path = '/foo1/foo2/foo3'
        }

    ) {
        It 'Does not modify data' {
            Find-Matches $data fuuuu
            $data.Count | Should -Be 4
        }

        It 'returns only leave result' {
            Find-Matches $data foo2 | Should -Be $foo2Path
        }

        It 'returns multiply results' {
            (Find-Matches $data foo | Measure-Object).Count | Should -Be 3
        }

        It 'should be case-insensitive' {
            Find-Matches $data FoO1 | Should -Be $foo1Path
        }

        It 'returns disk root folder for <rootQuery>' {
            Find-Matches $data $rootQuery | Should -Be $rootPath
        }

        It "should ignore trailing /"  -Skip:$IsWindows  {
            Find-Matches $data "$foo1Path/" | Should -Be $foo1Path
        }

        It "should ignore trailing \" -Skip:(-not $IsWindows) {
            Find-Matches $data "$foo1Path\" | Should -Be $foo1Path
        }
    }

    Context 'Different weight' {
        It 'Uses leaf match for <os>' -ForEach @(
            @{
                os = 'Windows'
                data = @{
                    'C:\admin' = 1.0
                    'C:\admin\monad' = 2.0
                }
                adminPath = 'C:\admin'
            }
            @{
                os = 'Linux'
                data = @{
                '/admin' = 1.0
                    '/admin/monad' = 2.0
                }
                adminPath = '/admin'
            }
        ) {
            Find-Matches $data 'adm' | Should -Be $adminPath
        }
    }

    Context 'Prefer prefix over weight' {
        It 'Uses prefix match' -ForEach @(
            @{
                os = 'Windows'
                fooPath = 'C:\foo'
                afooPath = 'C:\afoo'
                data = @{
                    'C:\foo' = 1.0
                    'C:\afoo' = 1000.0
                }
            } 
            @{
                os = 'Linux'
                fooPath = '/foo'
                afooPath = '/afoo'
                data = @{
                    '/foo' = 1.0
                    '/afoo' = 1000.0
                }
            }
        ) {
            Find-Matches $data 'fo' | Should -Be @($fooPath, $afooPath)
        }
    }

    Context 'Prefer exact match over weight and prefix' {

        It 'Uses prefix match' -ForEach @(
            @{
                os = 'Windows'
                fooPath = 'C:\foo'
                foo2Path = 'C:\foo2'
                data = @{
                    'C:\foo' = 1.0
                    'C:\foo2' = 1000.0
                }
            } 
            @{
                os = 'Linux'
                fooPath = '/foo'
                foo2Path = '/foo2'
                data = @{
                    '/foo' = 1.0
                    '/foo2' = 1000.0
                }
            }

        ) {
            Find-Matches $data 'foo' | Should -Be @($fooPath, $foo2Path)
        }
    }
}
