$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Html\Out-HtmlSection' {

        BeforeAll {
            $Document = Document -Name 'TestDocument' -ScriptBlock { }
            $pscriboDocument = $Document
        }
        

        It 'calls Out-HtmlParagraph' {
            Mock -CommandName Out-HtmlParagraph

            Section -Name TestSection -ScriptBlock { Paragraph 'TestParagraph' } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlParagraph -Exactly -Times 1
        }

        It 'calls Out-HtmlParagraph twice' {
            Mock -CommandName Out-HtmlParagraph

            Section -Name TestSection -ScriptBlock { Paragraph 'TestParagraph'; Paragraph 'TestParagraph'; } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlParagraph -Exactly -Times 2
        }

        It 'calls Out-HtmlTable' {
            Mock -CommandName Out-HtmlTable

            Section -Name TestSection -ScriptBlock { Get-Process | Select-Object -First 3 | Table TestTable } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlTable -Exactly -Times 1
        }

        It 'calls Out-HtmlPageBreak' {
            Mock -CommandName Out-HtmlPageBreak

            Section -Name TestSection -ScriptBlock { PageBreak } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlPageBreak -Exactly -Times 1
        }

        It 'calls Out-HtmlLineBreak' {
            Mock -CommandName Out-HtmlLineBreak

            Section -Name TestSection -ScriptBlock { LineBreak } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlLineBreak -Exactly -Times 1
        }

        It 'calls Out-HtmlBlankLine' {
            Mock -CommandName Out-HtmlBlankLine

            Section -Name TestSection -ScriptBlock { BlankLine } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlBlankLine -Exactly -Times 1
        }

        It 'warns on call Out-HtmlTOC' {
            Mock -CommandName Out-HtmlTOC

            Section -Name TestSection -ScriptBlock { TOC 'TestTOC' } | Out-HtmlSection -WarningAction SilentlyContinue

            Should -Invoke -CommandName Out-HtmlTOC -Exactly -Times 0
        }

        It 'encodes HTML section name' {
            $sectionName = 'Test & Section'
            $expected = '<h1 class="Normal">{0}</h1>' -f $sectionName.Replace('&','&amp;')

            $result = Section -Name $sectionName -ScriptBlock { BlankLine } | Out-HtmlSection

            $result -match $expected | Should -Be $true
        }

        It 'outputs indented section (#73)' {
            $sectionName = 'Test & Section'
            $expected = '<div style="margin-left: 6.00rem;">[\S\s]+</div>'

            $result = Section -Name $sectionName -ScriptBlock { BlankLine } -Tabs 2 | Out-HtmlSection
            $result -match $expected | Should -Be $true
        }

        It 'calls nested Out-XmlSection' {
            ## Note this must be called last in the Describe script block as the Out-XmlSection gets mocked!
            Mock -CommandName Out-HtmlSection

            Section -Name TestSection -ScriptBlock { Section -Name SubSection { } } | Out-HtmlSection

            Should -Invoke -CommandName Out-HtmlSection -Exactly -Times 1
        }
    }
}
