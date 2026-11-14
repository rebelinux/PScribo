$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Html\Out-HtmlDocument' {

        BeforeAll {
            $path = (Get-PSDrive -Name TestDrive).Root
        }

        It 'warns when 7 nested sections are defined' {
            $testDocument = Document -Name 'IllegalNestedSections' -ScriptBlock {
                Section -Name 'Level1' {
                    Section -Name 'Level2' {
                        Section -Name 'Level3' {
                            Section -Name 'Level4' {
                                Section -Name 'Level5' {
                                    Section -Name 'Level6' {
                                        Section -Name 'Level7' { }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            { $testDocument | Out-HtmlDocument -Path $path -WarningAction Stop 3>&1 } | Should -Throw '*6 heading*'
        }

        It 'calls Out-HtmlSection' {
            Mock -CommandName Out-HtmlSection

            Document -Name 'TestDocument' -ScriptBlock { Section -Name 'TestSection' -ScriptBlock { } } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlSection -Exactly -Times 1;
        }

        It 'calls Out-HtmlParagraph' {
            Mock -CommandName Out-HtmlParagraph

            Document -Name 'TestDocument' -ScriptBlock { Paragraph 'TestParagraph' } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlParagraph -Exactly -Times 1
        }

        It 'calls Out-HtmlTable' {
            Mock -CommandName Out-HtmlTable

            Document -Name 'TestDocument' -ScriptBlock { Get-Process | Select-Object -First 1 | Table 'TestTable' } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlTable -Exactly -Times 1
        }

        It 'calls Out-HtmlLineBreak' {
            Mock -CommandName Out-HtmlLineBreak

            Document -Name 'TestDocument' -ScriptBlock { LineBreak; } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlLineBreak -Exactly -Times 1
        }

        It 'calls Out-HtmlPageBreak' {
            Mock -CommandName Out-HtmlPageBreak

            Document -Name 'TestDocument' -ScriptBlock { PageBreak; } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlPageBreak -Exactly -Times 1
        }

        It 'calls Out-HtmlTOC' {
            Mock -CommandName Out-HtmlTOC

            Document -Name 'TestDocument' -ScriptBlock { TOC -Name 'TestTOC'; } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlTOC -Exactly -Times 1
        }

        It 'calls Out-HtmlBlankLine' {
            Mock -CommandName Out-HtmlBlankLine

            Document -Name 'TestDocument' -ScriptBlock { BlankLine; } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlBlankLine -Exactly -Times 1
        }

        It 'calls Out-HtmlBlankLine twice' {
            Mock -CommandName Out-HtmlBlankLine

            Document -Name 'TestDocument' -ScriptBlock { BlankLine; BlankLine; } | Out-HtmlDocument -Path $path

            Should -Invoke -CommandName Out-HtmlBlankLine -Exactly -Times 2 ## Mock calls are cumalative
        }
    }
}
