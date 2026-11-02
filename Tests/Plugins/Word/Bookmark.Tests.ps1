$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginsRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginsRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    function Get-TestXmlNode
    {
        param
        (
            [System.Xml.XmlDocument] $XmlDocument,
            [System.String] $XPath
        )
        $namespaceManager = New-Object -TypeName 'System.Xml.XmlNamespaceManager' -ArgumentList $XmlDocument.NameTable
        $namespaceManager.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
        return ,@($XmlDocument.SelectNodes($XPath, $namespaceManager))
    }

    Describe 'Plugins\Word\Bookmarks' {

        It 'wraps the section heading in a bookmark' {
            $document = Document -Name 'T' { Section -Name 'Heading' -Id 'sec-1' { Paragraph 'x' } }

            $xml = Get-WordDocument -Document $document
            $start = Get-TestXmlNode -XmlDocument $xml -XPath '//w:p[w:bookmarkStart]'

            $start.Count | Should Be 1
            $start[0].InnerText | Should Match 'Heading'
            $start[0].LastChild.LocalName | Should Be 'bookmarkEnd'
            $start[0].FirstChild.LocalName | Should Be 'pPr'
        }

        It 'puts a bookmark in the first cell of a table' {
            $document = Document -Name 'T' {
                Table -Name 'Tbl' -Id 'tbl-1' -InputObject ([PSCustomObject] @{ A = 1 }, [PSCustomObject] @{ A = 2 })
            }

            $xml = Get-WordDocument -Document $document

            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:bookmarkStart').Count | Should Be 1
            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:tr[1]//w:bookmarkStart').Count | Should Be 1
        }

        It 'puts an anchor token in a table cell as an empty bookmark and keeps the text' {
            $document = Document -Name 'T' {
                Table -Name 'Tbl' -InputObject ([PSCustomObject] @{ A = '{0}Row' -f (Get-PScriboAnchor -Id 'row-1') })
            }

            $xml = Get-WordDocument -Document $document

            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:bookmarkStart').Count | Should Be 1
            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:tc[w:p/w:bookmarkStart]')[0].InnerText | Should Match 'Row'
        }

        It 'emits unique bookmark ids and names with valid names' {
            $document = Document -Name 'T' {
                Section -Name 'A' -Id 'Same Id' { }
                Section -Name 'B' -Id 'same-id' { Table -Name 'T' -Id (('y' * 80)) -InputObject ([PSCustomObject] @{ A = 1 }) }
            }

            $xml = Get-WordDocument -Document $document
            $starts = Get-TestXmlNode -XmlDocument $xml -XPath '//w:bookmarkStart'
            $ids = $starts | ForEach-Object { $_.GetAttribute('id', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') }
            $names = $starts | ForEach-Object { $_.GetAttribute('name', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main') }

            $starts.Count | Should Be 3
            @($ids | Select-Object -Unique).Count | Should Be 3
            @($names | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique).Count | Should Be 3
            foreach ($name in $names)
            {
                $name | Should Match '^[A-Za-z][A-Za-z0-9_]{0,39}$'
            }
            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:bookmarkEnd').Count | Should Be 3
        }

        It 'does not output bookmarks for sections without an Id' {
            $document = Document -Name 'T' { Section -Name 'A' { Paragraph 'x' } }

            (Get-TestXmlNode -XmlDocument (Get-WordDocument -Document $document) -XPath '//w:bookmarkStart').Count | Should Be 0
        }
    }
}
