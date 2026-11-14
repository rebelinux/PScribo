$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    
    


    Describe 'Plugins\Text\Out-TextLineBreak' {
        ## Scaffold document options
        BeforeAll {
            $pscriboDocument = Document -Name 'TestDocument' -ScriptBlock {}
            $Options = New-PScriboTextOption
        }
        ;

        It 'Defaults to 120 and includes new line' {
            $expected = 122
            if (($PSVersionTable['PSEdition'] -eq 'Core') -and (-not $IsWindows)) { $expected -= 1 }

            $l = Out-TextLineBreak

            $l.Length | Should -Be $expected
        }

        It 'Truncates to 40 and includes new line' {
            $Options = New-PScriboTextOption -TextWidth 40 -SeparatorWidth 40
            $expected = 42
            if (($PSVersionTable['PSEdition'] -eq 'Core') -and (-not $IsWindows)) { $expected -= 1 }

            $l = Out-TextLineBreak

            $l.Length | Should -Be $expected
        }

        It 'Wraps lines and includes new line' {
            $Options = New-PScriboTextOption -TextWidth 40 -SeparatorWidth 80
            $expected = 84
            if (($PSVersionTable['PSEdition'] -eq 'Core') -and (-not $IsWindows)) { $expected -= 2 }

            $l = Out-TextLineBreak

            $l.Length | Should -Be $expected
        }
    }
}
