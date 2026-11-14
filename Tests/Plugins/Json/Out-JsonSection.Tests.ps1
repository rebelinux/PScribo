$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Json\Out-JsonSection' {

        BeforeAll {
            $Document = Document -Name 'TestDocument' -ScriptBlock { }
            $pscriboDocument = $Document
        }
        

        It 'calls Out-JsonParagraph' {
            Mock -CommandName Out-JsonParagraph

            Section -Name TestSection -ScriptBlock { Paragraph 'TestParagraph' } | Out-JsonSection

            Should -Invoke -CommandName Out-JsonParagraph -Exactly -Times 1
        }

        It 'calls Out-JsonParagraph twice' {
            Mock -CommandName Out-JsonParagraph

            Section -Name TestSection -ScriptBlock { Paragraph 'TestParagraph'; Paragraph 'TestParagraph'; } | Out-JsonSection

            Should -Invoke -CommandName Out-JsonParagraph -Exactly -Times 2
        }

        It 'calls Out-JsonTable' {
            Mock -CommandName Out-JsonTable

            Section -Name TestSection -ScriptBlock { Get-Process | Select-Object -First 3 | Table TestTable } | Out-JsonSection

            Should -Invoke -CommandName Out-JsonTable -Exactly -Times 1
        }

        It 'warns on call Out-JsonTOC' {
            Mock -CommandName Out-JsonTOC

            Section -Name TestSection -ScriptBlock { TOC 'TestTOC' } | Out-JsonSection -WarningAction SilentlyContinue

            Should -Invoke -CommandName Out-JsonTOC -Exactly -Times 0
        }

        It 'calls nested Out-JsonSection' {
            ## Note this must be called last in the Describe script block as the Out-XmlSection gets mocked!
            Mock -CommandName Out-JsonSection

            Section -Name TestSection -ScriptBlock { Section -Name SubSection { } } | Out-JsonSection

            Should -Invoke -CommandName Out-JsonSection -Exactly -Times 1
        }
    }
}
