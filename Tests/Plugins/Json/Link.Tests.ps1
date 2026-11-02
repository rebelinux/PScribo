$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginsRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginsRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Json\Links (external)' {

        $Document = Document -Name 'Test' -ScriptBlock { }
        $pscriboDocument = $Document
        $script:currentPageNumber = 1

        It 'outputs a plain string for paragraphs without links' {
            (Paragraph 'Plain' | Out-JsonParagraph) | Should BeExactly 'Plain'
        }

        It 'outputs structured text and link items for paragraphs with links' {
            $result = Paragraph { Text 'See'; Link 'GitHub' -Uri 'https://github.com' } | Out-JsonParagraph

            $result.Count | Should Be 2
            $result[0].type | Should Be 'text'
            $result[0].text | Should Be 'See '
            $result[1].type | Should Be 'link'
            $result[1].text | Should Be 'GitHub'
            $result[1].target | Should Be 'https://github.com'
            $result[1].external | Should Be $true
            $result[1].resolved | Should Be $true
        }

        It 'flags a rejected uri as unresolved' {
            $result = Paragraph { Link 'Bad' -Uri 'javascript://alert(1)' } | Out-JsonParagraph

            $result[0].resolved | Should Be $false
        }

        It 'replaces link tokens in table cells with their text' {
            $table = Table -Name 'T' -InputObject ([PSCustomObject] @{ Name = 'x'; Doc = '<!#Link:https://github.com|GitHub#!>' })

            $rows = @(Out-JsonTable -Table $table)[0]

            $rows.Doc | Should Be 'GitHub > (https://github.com)'
        }

        It 'does not alter the source table' {
            $table = Table -Name 'T' -InputObject ([PSCustomObject] @{ Name = 'x'; Doc = '<!#Link:https://github.com|GitHub#!>' })

            $null = Out-JsonTable -Table $table

            $table.Rows[0].Doc | Should Be '<!#Link:https://github.com|GitHub#!>'
        }
    }
}
