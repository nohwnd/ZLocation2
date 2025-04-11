Describe 'ZLocation.Storage' {

    BeforeAll {
        ${function:Add-ZWeight} = & (Get-Module ZLocation2) { Get-Command Add-ZWeight -Module ZLocation2 }
    }

    BeforeEach {
        # Clear the ZLocation2 test database
        Remove-Item $PSScriptRoot/../testdb.db -ErrorAction Ignore
    }

    It 'can add weight' {        
        $w1 = 6.6
        $w2 = 10.0

        Add-ZWeight -path "add-weight" -weight $w1
        @(Get-ZLocation -Match "add-weight").Weight | Should -Be $w1

        Add-ZWeight -path "add-weight" -weight $w2
        @(Get-ZLocation -Match "add-weight").Weight | Should -Be ($w1 + $w2)
    }

    It 'can add path' {
        $originalCount = @(Get-ZLocation).Count

        Add-ZWeight -path "add-path" -weight 1.0

        @(Get-ZLocation).Count | Should -Be ($originalCount + 1)
    }

    It 'can filter paths' {
        Add-ZWeight -path "some-path" -weight 1.0
        Add-ZWeight -path "other-path" -weight 1.0

        $h = Get-ZLocation -Match "some"
        $h.Path | Should -Contain "some-path"
        $h.Path | Should -Not -Contain "other-path"
    }

    It 'can filter paths with multiple filters' {
        Add-ZWeight -path "some-path" -weight 1.0
        Add-ZWeight -path "other-path" -weight 1.0

        $h = Get-ZLocation -Match "some", "other"
        $h.Path | Should -Contain "some-path"
        $h.Path | Should -Contain "other-path"
    }

    It 'can handle multiple paths differing only by capitalization' {
        $originalCount = @(Get-ZLocation).Count

        Add-ZWeight -path "new-path" -weight 1
        Add-ZWeight -path "new-path-2" -weight 1

        @(Get-ZLocation).Count | Should -Be ($originalCount + 2)
    }

    It 'can remove path' {
        Add-ZWeight -path "path1" -weight 1.0
        
        $originalCount = @(Get-ZLocation).Count

        Remove-ZLocation -path "path1"

        @(Get-ZLocation).Count | Should -Be ($originalCount - 1)
    }
}
