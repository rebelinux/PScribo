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
        $namespaceManager.AddNamespace('r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
        return ,@($XmlDocument.SelectNodes($XPath, $namespaceManager))
    }

    Describe 'Plugins\Word\Links (external)' {

        It 'outputs a w:hyperlink with a relationship id for an external link' {
            $document = Document -Name 'TestDocument' {
                Paragraph { Text 'See'; Link 'GitHub' -Uri 'https://github.com' }
            }

            $xml = Get-WordDocument -Document $document
            $hyperlinks = Get-TestXmlNode -XmlDocument $xml -XPath '//w:hyperlink'

            $hyperlinks.Count | Should Be 1
            $hyperlinks[0].GetAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships') | Should Be 'rIdLink1'
            $hyperlinks[0].InnerText | Should Be 'GitHub'
        }

        It 'applies the Hyperlink character style to the link run' {
            $document = Document -Name 'TestDocument' {
                Paragraph { Link 'GitHub' -Uri 'https://github.com' }
            }

            $xml = Get-WordDocument -Document $document

            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:hyperlink/w:r/w:rPr/w:rStyle[@w:val="Hyperlink"]').Count | Should Be 1
        }

        It 'reuses a single relationship for the same uri' {
            $document = Document -Name 'TestDocument' {
                Paragraph { Link 'One' -Uri 'https://github.com'; Link 'Two' -Uri 'https://github.com' }
            }

            $xml = Get-WordDocument -Document $document
            $ids = Get-TestXmlNode -XmlDocument $xml -XPath '//w:hyperlink/@r:id' | ForEach-Object { $_.Value } | Select-Object -Unique

            @($ids).Count | Should Be 1
            $script:pscriboWordHyperlinks.Count | Should Be 1
        }

        It 'outputs the link in a table cell' {
            $document = Document -Name 'TestDocument' {
                Table -Name 'T' -InputObject ([PSCustomObject] @{ Name = 'x'; Doc = '<!#Link:https://github.com|GitHub#!>' })
            }

            $xml = Get-WordDocument -Document $document
            $hyperlinks = Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:hyperlink'

            $hyperlinks.Count | Should Be 1
            $hyperlinks[0].InnerText | Should Be 'GitHub'
        }

        It 'renders a rejected uri as plain text and writes a warning' {
            $warnings = @()
            $document = Document -Name 'TestDocument' {
                Paragraph { Link 'Bad' -Uri 'javascript://alert(1)' }
            } -WarningVariable warnings -WarningAction SilentlyContinue

            $xml = Get-WordDocument -Document $document

            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:hyperlink').Count | Should Be 0
            $xml.DocumentElement.InnerText | Should Be 'Bad'
            @($warnings).Count | Should BeGreaterThan 0
        }

        It 'keeps text before and after the link in order' {
            $document = Document -Name 'TestDocument' {
                Paragraph { Text 'Before' -NoSpace; Link 'GitHub' -Uri 'https://github.com' -NoSpace; Text 'After' }
            }

            $xml = Get-WordDocument -Document $document

            $xml.DocumentElement.InnerText | Should Be 'BeforeGitHubAfter'
        }

        It 'declares the Hyperlink style when the document has links' {
            $document = Document -Name 'TestDocument' {
                Paragraph { Link 'GitHub' -Uri 'https://github.com' }
            }

            $styles = Get-WordStylesDocument -Styles $document.Styles -TableStyles $document.TableStyles

            (Get-TestXmlNode -XmlDocument $styles -XPath '//w:style[@w:styleId="Hyperlink"]').Count | Should Be 1
        }

        It 'does not declare the Hyperlink style when the document has no links' {
            $document = Document -Name 'TestDocument' { Paragraph 'No links' }

            $styles = Get-WordStylesDocument -Styles $document.Styles -TableStyles $document.TableStyles

            (Get-TestXmlNode -XmlDocument $styles -XPath '//w:style[@w:styleId="Hyperlink"]').Count | Should Be 0
        }
    }

    Describe 'Plugins\Word\Out-WordDocument (links)' {

        $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('pscribo-links-{0}' -f [System.Guid]::NewGuid())
        $null = New-Item -Path $testPath -ItemType Directory

        function Get-DocxEntryXml
        {
            param ($Path, $EntryName)
            Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
            $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
            try
            {
                $reader = New-Object -TypeName 'System.IO.StreamReader' -ArgumentList $zip.GetEntry($EntryName).Open()
                $xml = New-Object -TypeName 'System.Xml.XmlDocument'
                $xml.LoadXml($reader.ReadToEnd())
                $reader.Dispose()
                return $xml
            }
            finally
            {
                $zip.Dispose()
            }
        }

        It 'writes a well formed docx with an external hyperlink relationship' {
            $document = Document -Name 'ExternalLinks' {
                Paragraph { Text 'See'; Link 'GitHub' -Uri 'https://github.com/iainbrighton/PScribo?a=1&b=2' }
            }

            $file = Out-WordDocument -Document $document -Path $testPath
            $documentXml = Get-DocxEntryXml -Path $file.FullName -EntryName 'word/document.xml'
            $relsXml = Get-DocxEntryXml -Path $file.FullName -EntryName 'word/_rels/document.xml.rels'

            $relationship = @(Get-TestXmlNode -XmlDocument $documentXml -XPath '//w:hyperlink')
            $relationship.Count | Should Be 1
            $rels = @($relsXml.DocumentElement.ChildNodes | Where-Object { $_.Id -eq 'rIdLink1' })
            $rels.Count | Should Be 1
            $rels[0].TargetMode | Should Be 'External'
            $rels[0].Target | Should Be 'https://github.com/iainbrighton/PScribo?a=1&b=2'
            $rels[0].Type | Should Match 'relationships/hyperlink$'
        }

        It 'does not carry link relationships into the next document' {
            $document = Document -Name 'NoLinks' { Paragraph 'Plain' }

            $file = Out-WordDocument -Document $document -Path $testPath
            $relsXml = Get-DocxEntryXml -Path $file.FullName -EntryName 'word/_rels/document.xml.rels'

            @($relsXml.DocumentElement.ChildNodes | Where-Object { $_.Type -match 'hyperlink' }).Count | Should Be 0
        }

        Remove-Item -Path $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
