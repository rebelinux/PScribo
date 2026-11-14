$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Text\Out-TextSection' {

        BeforeAll {
            $Document = Document -Name 'TestDocument' -ScriptBlock { }
            $pscriboDocument = $Document
        }
        

        It 'outputs indented section (#73)' {
            $result = Section -Name TestSection -ScriptBlock { } -Tabs 2 | Out-TextSection

            $result -match '^\r?\n        ' | Should -Be $true
        }

        It 'calls Out-TextParagraph' {
            Mock -CommandName Out-TextParagraph

            Section -Name TestSection -ScriptBlock { Paragraph 'TestParagraph' } | Out-TextSection

            Should -Invoke -CommandName Out-TextParagraph -Exactly -Times 1
        }

        It 'calls Out-TextParagraph twice' {
            Mock -CommandName Out-TextParagraph

            Section -Name TestSection -ScriptBlock { Paragraph 'TestParagraph'; Paragraph 'TestParagraph'; } | Out-TextSection

            Should -Invoke -CommandName Out-TextParagraph -Exactly -Times 2
        }

        It 'calls Out-TextTable' {
            Mock -CommandName Out-TextTable

            Section -Name TestSection -ScriptBlock { Get-Process | Select-Object -First 3 | Table TestTable } | Out-TextSection

            Should -Invoke -CommandName Out-TextTable -Exactly -Times 1
        }

        It 'calls Out-TextPageBreak' {
            Mock -CommandName Out-TextPageBreak

            Section -Name TestSection -ScriptBlock { PageBreak } | Out-TextSection

            Should -Invoke -CommandName Out-TextPageBreak -Exactly -Times 1
        }

         It 'calls Out-TextLineBreak' {
            Mock -CommandName Out-TextLineBreak

            Section -Name TestSection -ScriptBlock { LineBreak } | Out-TextSection

            Should -Invoke -CommandName Out-TextLineBreak -Exactly -Times 1
        }

        It 'calls Out-TextBlankLine' {
            Mock -CommandName Out-TextBlankLine

            Section -Name TestSection -ScriptBlock { BlankLine } | Out-TextSection

            Should -Invoke -CommandName Out-TextBlankLine -Exactly -Times 1
        }

        It 'warns on call Out-TextTOC' {
            Mock -CommandName Out-TextTOC

            Section -Name TestSection -ScriptBlock { TOC 'TestTOC' } | Out-TextSection -WarningAction SilentlyContinue

            Should -Invoke -CommandName Out-TextTOC -Exactly -Times 0
        }

        It 'calls nested Out-TextSection' {
            ## Note this must be called last in the Describe script block as the Out-XmlSection gets mocked!
            Mock -CommandName Out-TextSection

            Section -Name TestSection -ScriptBlock { Section -Name SubSection { } } | Out-TextSection

            Should -Invoke -CommandName Out-TextSection -Exactly -Times 1
        }
    }
}
