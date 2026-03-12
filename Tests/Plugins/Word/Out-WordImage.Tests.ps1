$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginsRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginsRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Word\Out-WordImage' {

        BeforeEach {
            $testXmlDocument = [System.Xml.XmlDocument]::new()
            [ref] $null = $testXmlDocument.AppendChild($testXmlDocument.CreateElement('w', 'body', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'))
        }

        It 'outputs inline container element by default' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Inline'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wp:inline'
        }

        It 'does not output anchor element when Wrap is Inline' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Inline'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Not -Match 'wp:anchor'
        }

        It 'outputs anchor element when Wrap is Square' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Square'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wp:anchor'
        }

        It 'outputs wrapSquare element when Wrap is Square' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Square'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapSquare'
        }

        It 'outputs wrapTight element when Wrap is Tight' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Tight'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapTight'
        }

        It 'outputs wrapPolygon element when Wrap is Tight' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Tight'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapPolygon'
        }

        It 'outputs wrapThrough element when Wrap is Through' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Through'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapThrough'
        }

        It 'outputs wrapPolygon element when Wrap is Through' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Through'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapPolygon'
        }

        It 'outputs wrapTopAndBottom element when Wrap is TopBottom' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'TopBottom'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapTopAndBottom'
        }

        It 'outputs wrapNone element when Wrap is None' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'None'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'wrapNone'
        }

        It 'outputs positionH element when Wrap is not Inline' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Square'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'positionH'
        }

        It 'outputs positionV element when Wrap is not Inline' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Square'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'positionV'
        }

        It 'outputs posOffset element when Wrap is not Inline' {
            $testImage = [PSCustomObject] @{ ImageNumber = 1; Name = 'Image1'; Align = 'Left'; Wrap = 'Square'; WidthEm = 100; HeightEm = 100 }

            $result = Out-WordImage -Image $testImage -XmlDocument $testXmlDocument

            $result.OuterXml | Should -Match 'posOffset'
        }
    }
}



