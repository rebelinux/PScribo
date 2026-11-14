$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$testRoot = Split-Path -Path $here -Parent
$moduleRoot = Split-Path -Path $testRoot -Parent
Import-Module -Name "$moduleRoot\PScribo.psm1" -Force

InModuleScope -ModuleName 'PScribo' -ScriptBlock {

    

    Describe -Name 'ConvertTo-Image' {
        $Platform = if ($PSVersionTable.PSEdition -eq 'Core') {
            if ($IsLinux -or $IsMacOS) {
                    'Unix'
                }
                else {
                    'Windows'
                }
            }
            else {
                'Windows'
            }
        BeforeAll {
            $testRoot = Split-Path -Path $PSScriptRoot -Parent
        }

        It "returns 'System.Drawing.Image' type" -Skip:$($Platform -eq 'Unix') {
            $testPath = Join-Path -Path $testRoot -ChildPath 'TestImage.jpg'
            $testUri = Resolve-ImageUri -Path $testPath
            $testBytes = Get-UriBytes -Uri $testUri

            $result = ConvertTo-Image -Bytes $testBytes

            $result -is [System.Drawing.Image] | Should -Be $true
        }
        It "returns 'SkiaSharp.SKImage' type" -Skip:$($Platform -ne 'Unix') {
            $testPath = Join-Path -Path $testRoot -ChildPath 'TestImage.jpg'
            $testUri = Resolve-ImageUri -Path $testPath
            $testBytes = Get-UriBytes -Uri $testUri

            $result = ConvertTo-Image -Bytes $testBytes

            $result -is [SkiaSharp.SKImage] | Should -Be $true
        }

    }
}
