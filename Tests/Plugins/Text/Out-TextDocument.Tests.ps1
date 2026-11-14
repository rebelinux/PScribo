$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    
    

    Describe 'Plugins\Text\Out-TextDocument' {
        BeforeAll {
            $isNix = $false
            if (($PSVersionTable['PSEdition'] -eq 'Core') -and (-not $IsWindows))
                {
                    $isNix = $true
                }
        }


        BeforeAll {
            $path = (Get-PSDrive -Name TestDrive).Root
        };

        It 'calls Out-TextSection' {
            Mock -CommandName Out-TextSection

            Document -Name 'TestDocument' -ScriptBlock { Section -Name 'TestSection' -ScriptBlock { } } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextSection -Exactly -Times 1
        }

        It 'calls Out-TextParagraph' {
            Mock -CommandName Out-TextParagraph

            Document -Name 'TestDocument' -ScriptBlock { Paragraph 'TestParagraph' } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextParagraph -Exactly -Times 1
        }

        It 'calls Out-TextLineBreak' {
            Mock -CommandName Out-TextLineBreak

            Document -Name 'TestDocument' -ScriptBlock { LineBreak; } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextLineBreak -Exactly -Times 1
        }

        It 'calls Out-TextPageBreak' {
            Mock -CommandName Out-TextPageBreak

            Document -Name 'TestDocument' -ScriptBlock { PageBreak; } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextPageBreak -Exactly -Times 1
        }

         It 'calls Out-TextTable' {
            Mock -CommandName Out-TextTable

            Document -Name 'TestDocument' -ScriptBlock { Get-Process | Select-Object -First 1 | Table 'TestTable' } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextTable -Exactly -Times 1
        }

        It 'calls Out-TextTOC' {
            Mock -CommandName Out-TextTOC

            Document -Name 'TestDocument' -ScriptBlock { TOC -Name 'TestTOC'; } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextTOC -Exactly -Times 1
        }

        It 'calls Out-TextBlankLine' {
            Mock -CommandName Out-TextBlankLine

            Document -Name 'TestDocument' -ScriptBlock { BlankLine; } | Out-TextDocument -Path $path

            Should -Invoke -CommandName Out-TextBlankLine -Exactly -Times 1
        }

        It 'calls Out-TextBlankLine twice' {
            Mock -CommandName Out-TextBlankLine
            
            Document -Name 'TestDocument' -ScriptBlock { BlankLine; BlankLine; } | Out-TextDocument -Path $path;

            Should -Invoke -CommandName Out-TextBlankLine -Exactly -Times 2 ## Mock calls are cumalative
        }
    }
}
