$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginsRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginsRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Text\Links (external)' {

        $Document = Document -Name 'Test' -ScriptBlock { }
        $pscriboDocument = $Document
        $Options = New-PScriboTextOption
        $script:currentPageNumber = 1

        It 'outputs the display text followed by the uri' {
            $result = Paragraph { Text 'See'; Link 'GitHub' -Uri 'https://github.com' } | Out-TextParagraph

            $result | Should BeExactly ('See GitHub > (https://github.com){0}' -f [System.Environment]::NewLine)
        }

        It 'outputs plain text for a rejected uri' {
            $result = Paragraph { Link 'Bad' -Uri 'javascript://alert(1)' } | Out-TextParagraph

            $result | Should BeExactly ('Bad{0}' -f [System.Environment]::NewLine)
        }

        It 'does not write to the host when outputting a paragraph' {
            $hostOutput = Paragraph { Text 'Hello'; Link 'GitHub' -Uri 'https://github.com' } | Out-TextParagraph 6>&1 |
                Where-Object { $_ -is [System.Management.Automation.InformationRecord] }

            @($hostOutput).Count | Should Be 0
        }
    }
}
