$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Html\Out-HtmlImage' {

        It "aligns image '<Alignment>'" -ForEach @(
            @{ Alignment = 'Left' }
            @{ Alignment = 'Center' }
            @{ Alignment = 'Right' }
        ) {
            param ($Alignment)

            $testImage = [PSCustomObject] @{
                Align    = $Alignment
                Bytes    = [byte[]] @(0,1,2,3)
                MimeType = 'image/jpg'
                Text     = 'Dummy Image'
                Height   = 0
                Width    = 0
            }

            $expected = '<div align="{0}">' -f $Alignment

            $result = Out-HtmlImage -Image $testImage

            $result -match $expected | Should -Be $true
        }

        It 'sets image Mime type' {
            $testImage = [PSCustomObject] @{
                Align    = 'Left'
                Bytes    = [byte[]] @(0,1,2,3)
                MimeType = 'image/jpg'
                Text     = 'Dummy Image'
                Height   = 123
                Width    = 321
            }
            $expected = 'data:{0}' -f $testImage.MimeType

            $result = Out-HtmlImage -Image $testImage

            $result -match $expected | Should -Be $true
        }

        It 'sets image height' {
            $testImage = [PSCustomObject] @{
                Align    = 'Left'
                Bytes    = [byte[]] @(0,1,2,3)
                MimeType = 'image/jpg'
                Text     = 'Dummy Image'
                Height   = 123
                Width    = 321
            }
            $expected = 'height="{0}"' -f $testImage.Height

            $result = Out-HtmlImage -Image $testImage

            $result -match $expected | Should -Be $true
        }

        It 'sets image width' {
            $testImage = [PSCustomObject] @{
                Align    = 'Left'
                Bytes    = [byte[]] @(0,1,2,3)
                MimeType = 'image/jpg'
                Text     = 'Dummy Image'
                Height   = 123
                Width    = 321
            }
            $expected = 'width="{0}"' -f $testImage.Width

            $result = Out-HtmlImage -Image $testImage

            $result -match $expected | Should -Be $true
        }

        It 'adds alttext to image' {
            $testImage = [PSCustomObject] @{
                Align    = 'Left'
                Bytes    = [byte[]] @(0,1,2,3)
                MimeType = 'image/jpg'
                Text     = 'Dummy Image'
                Height   = 0
                Width    = 0
            }
            $expected = 'alt="{0}"' -f $testImage.Text

            $result = Out-HtmlImage -Image $testImage

            $result -match $expected | Should -Be $true
        }
    }
}
