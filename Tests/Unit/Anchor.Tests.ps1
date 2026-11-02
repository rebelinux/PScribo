$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$testRoot  = Split-Path -Path $here -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Resolve-PScriboAnchorName' {

        It 'keeps a simple valid Id unchanged' {
            Resolve-PScriboAnchorName -Id 'Teams_Overview1' | Should BeExactly 'Teams_Overview1'
        }

        It 'sanitises invalid characters and appends a deterministic hash' {
            $first = Resolve-PScriboAnchorName -Id 'Team: Sales & Marketing'
            $second = Resolve-PScriboAnchorName -Id 'Team: Sales & Marketing'

            $first | Should Be $second
            $first | Should Match '^[A-Za-z][A-Za-z0-9_]*_[0-9a-f]{8}$'
        }

        It 'prefixes an Id that does not start with a letter' {
            Resolve-PScriboAnchorName -Id '1abc' | Should Match '^A_1abc_[0-9a-f]{8}$'
        }

        It 'never exceeds 40 characters' {
            (Resolve-PScriboAnchorName -Id ('x' * 300)).Length | Should BeLessThan 41
            (Resolve-PScriboAnchorName -Id ('x' * 35)).Length | Should BeLessThan 41
        }

        It 'gives different names to Ids that sanitise to the same text' {
            (Resolve-PScriboAnchorName -Id 'a b') -ceq (Resolve-PScriboAnchorName -Id 'a-b') | Should Be $false
        }

        It 'avoids case-insensitive collisions with existing names' {
            $used = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
            $first = Resolve-PScriboAnchorName -Id 'Abc' -ExistingName $used
            $null = $used.Add($first)
            $second = Resolve-PScriboAnchorName -Id 'ABC' -ExistingName $used

            $first | Should Be 'Abc'
            $second | Should Be 'ABC_2'
        }
    }

    Describe 'Anchors' {

        It 'Section -Id and Table -Id store the link id' {
            $document = Document -Name 'T' {
                Section -Name 'S' -Id 'sec-1' { Table -Name 'Tbl' -Id 'tbl-1' -InputObject ([PSCustomObject] @{ A = 1 }) }
            }

            $document.Sections[0].LinkId | Should Be 'sec-1'
            $document.Sections[0].Sections[0].LinkId | Should Be 'tbl-1'
        }

        It 'does not change the existing GUID Id of a section' {
            $document = Document -Name 'T' { Section -Name 'S' -Id 'x' { } }

            $document.Sections[0].Id | Should Match '^[0-9a-f-]{36}$'
        }

        It 'builds a registry with valid names for sections, tables and anchor tokens' {
            $document = Document -Name 'T' {
                Section -Name 'S' -Id 'sec 1' {
                    Table -Name 'Tbl' -Id 'tbl-1' -InputObject ([PSCustomObject] @{ A = (Get-PScriboAnchor -Id 'row-9') })
                }
            }

            $anchors = $document.Properties['Anchors']
            $anchors.Count | Should Be 3
            $anchors['sec 1'].Type | Should Be 'Section'
            $anchors['tbl-1'].Type | Should Be 'Table'
            $anchors['row-9'].Type | Should Be 'Anchor'
            foreach ($entry in $anchors.Values)
            {
                $entry.Name | Should Match '^[A-Za-z][A-Za-z0-9_]{0,39}$'
            }
        }

        It 'warns about a duplicate Id and keeps the first definition' {
            $warnings = @()
            $document = Document -Name 'T' {
                Section -Name 'One' -Id 'dup' { }
                Section -Name 'Two' -Id 'dup' { }
            } -WarningVariable warnings -WarningAction SilentlyContinue

            $document.Properties['Anchors'].Count | Should Be 1
            $document.Properties['Anchors']['dup'].Title | Should Be 'One'
            @($warnings).Count | Should BeGreaterThan 0
        }

        It 'rejects an Id containing a pipe' {
            $threw = @()
            foreach ($id in 'a|b', 'a#!>b', "a`nb")
            {
                try { $null = Test-PScriboAnchorId -Id $id; $threw += $false } catch { $threw += $true }
            }
            ($threw -contains $false) | Should Be $false
        }

        It 'returns an anchor token' {
            Get-PScriboAnchor -Id 'x1' | Should BeExactly '<!#Anchor:x1#!>'
        }
    }
}
