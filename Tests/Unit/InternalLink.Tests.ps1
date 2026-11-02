$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$testRoot  = Split-Path -Path $here -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    $wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'

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

    Describe 'Internal links' {

        It 'Get-PScriboLink returns tokens for anchors and uris' {
            Get-PScriboLink -Anchor 'sec-1' -Text 'Go' | Should BeExactly '<!#Link:sec-1|Go#!>'
            Get-PScriboLink -Uri 'https://github.com' -Text 'Go' | Should BeExactly '<!#Link:https://github.com|Go#!>'
        }

        It 'Get-PScriboLink and Get-PScriboAnchor are exported for feature detection' {
            $exported = (Get-Module -Name PScribo).ExportedFunctions.Keys

            $exported -contains 'Get-PScriboLink' | Should Be $true
            $exported -contains 'Get-PScriboAnchor' | Should Be $true
        }

        It 'warns once about an unresolved anchor link and still creates the document' {
            $warnings = @()
            $document = Document -Name 'T' {
                Paragraph { Link -Anchor 'missing' -Text 'Nowhere' }
                Paragraph { Link -Anchor 'missing' -Text 'Nowhere again' }
            } -WarningVariable warnings -WarningAction SilentlyContinue

            @($warnings | Where-Object { $_ -match 'missing' }).Count | Should Be 1
            $document | Should Not BeNullOrEmpty
        }

        It 'resolves a link in a paragraph to a section defined later (forward reference)' {
            $document = Document -Name 'T' {
                Paragraph { Link -Anchor 'later' -Text 'Jump' }
                Section -Name 'Later' -Id 'later' { Paragraph 'x' }
            }

            $Document = $document
            $segment = Resolve-PScriboLinkSegment -Segment (@(Get-PScriboLinkSegment -Text '<!#Link:later|Jump#!>')[0])
            $segment.IsResolved | Should Be $true
            $segment.AnchorName | Should Be 'later'
        }
    }

    Describe 'Plugins\Word\Internal links' {

        It 'outputs w:hyperlink w:anchor matching the bookmark for a forward reference' {
            $document = Document -Name 'T' {
                Paragraph { Link -Anchor 'target 1' -Text 'Jump' }
                Section -Name 'Target' -Id 'target 1' { Paragraph 'x' }
            }

            $xml = Get-WordDocument -Document $document
            $hyperlink = Get-TestXmlNode -XmlDocument $xml -XPath '//w:hyperlink[@w:anchor]'
            $bookmark = Get-TestXmlNode -XmlDocument $xml -XPath '//w:bookmarkStart'

            $hyperlink.Count | Should Be 1
            $hyperlink[0].InnerText | Should Be 'Jump'
            $hyperlink[0].GetAttribute('anchor', $wNs) | Should Be $bookmark[0].GetAttribute('name', $wNs)
            $hyperlink[0].HasAttribute('id', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships') | Should Be $false
        }

        It 'links from a table cell to a table row anchor' {
            $document = Document -Name 'T' {
                Table -Name 'Index' -InputObject ([PSCustomObject] @{ Team = (Get-PScriboLink -Anchor 'team-b' -Text 'Team B') })
                Table -Name 'Details' -InputObject ([PSCustomObject] @{ Team = ('{0}Team B' -f (Get-PScriboAnchor -Id 'team-b')) })
            }

            $xml = Get-WordDocument -Document $document
            $hyperlink = Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:hyperlink[@w:anchor]'
            $bookmark = Get-TestXmlNode -XmlDocument $xml -XPath '//w:tbl//w:bookmarkStart'

            $hyperlink.Count | Should Be 1
            $bookmark.Count | Should Be 1
            $hyperlink[0].GetAttribute('anchor', $wNs) | Should Be $bookmark[0].GetAttribute('name', $wNs)
        }

        It 'renders an unresolved link as plain text without a w:hyperlink' {
            $document = Document -Name 'T' { Paragraph { Link -Anchor 'missing' -Text 'Nowhere' } } -WarningAction SilentlyContinue

            $xml = Get-WordDocument -Document $document

            (Get-TestXmlNode -XmlDocument $xml -XPath '//w:hyperlink').Count | Should Be 0
            $xml.DocumentElement.InnerText | Should Be 'Nowhere'
        }

        It 'defaults the link text to the section heading' {
            $document = Document -Name 'T' {
                Paragraph { Link -Anchor 'sec' }
                Section -Name 'My Heading' -Id 'sec' { }
            }

            (Get-TestXmlNode -XmlDocument (Get-WordDocument -Document $document) -XPath '//w:hyperlink')[0].InnerText | Should Be 'My Heading'
        }
    }

    Describe 'Plugins\Word\Out-WordDocument (internal links)' {

        $testPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('pscribo-ilinks-{0}' -f [System.Guid]::NewGuid())
        $null = New-Item -Path $testPath -ItemType Directory

        It 'writes a well formed docx where every w:anchor has a bookmark and bookmark ids are unique' {
            $document = Document -Name 'Internal' {
                Paragraph { Link -Anchor 'second' -Text 'Go to second'; Link 'External' -Uri 'https://github.com' }
                Section -Name 'First' -Id 'first' {
                    Table -Name 'Idx' -Id 'idx' -InputObject ([PSCustomObject] @{ A = (Get-PScriboLink -Anchor 'first' -Text 'first'); B = (Get-PScriboLink -Anchor 'nope' -Text 'bad') })
                }
                Section -Name 'Second' -Id 'second' { Paragraph { Link -Anchor 'idx' -Text 'Index' } }
            } -WarningAction SilentlyContinue

            $file = Out-WordDocument -Document $document -Path $testPath
            Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
            $zip = [System.IO.Compression.ZipFile]::OpenRead($file.FullName)
            try
            {
                $names = $zip.Entries | Where-Object { $_.FullName -like '*.xml' -or $_.FullName -like '*.rels' }
                foreach ($entry in $names)
                {
                    $reader = New-Object -TypeName 'System.IO.StreamReader' -ArgumentList $entry.Open()
                    $xml = New-Object -TypeName 'System.Xml.XmlDocument'
                    { $xml.LoadXml($reader.ReadToEnd()) } | Should Not Throw
                    $reader.Dispose()
                    if ($entry.FullName -eq 'word/document.xml')
                    {
                        $documentXml = $xml
                    }
                }
            }
            finally
            {
                $zip.Dispose()
            }

            $bookmarks = Get-TestXmlNode -XmlDocument $documentXml -XPath '//w:bookmarkStart'
            $bookmarkNames = @($bookmarks | ForEach-Object { $_.GetAttribute('name', $wNs) })
            $bookmarkIds = @($bookmarks | ForEach-Object { $_.GetAttribute('id', $wNs) })
            $anchors = @(Get-TestXmlNode -XmlDocument $documentXml -XPath '//w:hyperlink/@w:anchor' | ForEach-Object { $_.Value })

            $anchors.Count | Should Be 3
            foreach ($anchor in $anchors)
            {
                $bookmarkNames -contains $anchor | Should Be $true
            }
            @($bookmarkIds | Select-Object -Unique).Count | Should Be $bookmarkIds.Count
            @($bookmarkNames | Select-Object -Unique).Count | Should Be $bookmarkNames.Count
            (Get-TestXmlNode -XmlDocument $documentXml -XPath '//w:bookmarkEnd').Count | Should Be $bookmarks.Count
            foreach ($name in $bookmarkNames)
            {
                $name | Should Match '^[A-Za-z][A-Za-z0-9_]{0,39}$'
            }
        }

        It 'opens in Word when Word is available' {
            $word = $null
            try { $word = New-Object -ComObject 'Word.Application' -ErrorAction Stop } catch { }
            if ($null -eq $word)
            {
                Set-TestInconclusive -Message 'Word COM is not available.'
                return
            }
            try
            {
                $document = Document -Name 'WordOpen' {
                    Paragraph { Link -Anchor 'a' -Text 'Go' }
                    Section -Name 'A' -Id 'a' { }
                }
                $file = Out-WordDocument -Document $document -Path $testPath
                $opened = $word.Documents.Open($file.FullName, $false, $true)
                $opened.Hyperlinks.Count | Should Be 1
                $opened.Close($false)
            }
            finally
            {
                $word.Quit()
            }
        }

        Remove-Item -Path $testPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Describe 'Plugins\Html\Internal links' {

        $script:currentPageNumber = 1

        It 'outputs href to the id of a section defined later and the id on the heading' {
            $Document = Document -Name 'T' {
                Paragraph { Link -Anchor 'sec 1' -Text 'Jump' }
                Section -Name 'Heading' -Id 'sec 1' { }
            }
            $pscriboDocument = $Document
            $name = $Document.Properties['Anchors']['sec 1'].Name

            (Out-HtmlParagraph -Paragraph $Document.Sections[0]) | Should BeExactly ('<div><a href="#{0}">Jump</a></div>' -f $name)
            (Out-HtmlSection -Section $Document.Sections[1]) | Should Match ('id="{0}"' -f $name)
        }

        It 'renders an unresolved link as plain text' {
            $Document = Document -Name 'T' { Paragraph { Link -Anchor 'missing' -Text 'Nowhere' } } -WarningAction SilentlyContinue
            $pscriboDocument = $Document

            Out-HtmlParagraph -Paragraph $Document.Sections[0] | Should BeExactly '<div>Nowhere</div>'
        }

        It 'outputs an internal link in a table cell' {
            $Document = Document -Name 'T' {
                Table -Name 'T1' -InputObject ([PSCustomObject] @{ A = (Get-PScriboLink -Anchor 'tbl2' -Text 'See T2') })
                Table -Name 'T2' -Id 'tbl2' -InputObject ([PSCustomObject] @{ A = 1 })
            }
            $pscriboDocument = $Document

            Out-HtmlTable -Table $Document.Sections[0] | Should Match '<td><a href="#tbl2">See T2</a></td>'
        }
    }

    Describe 'Plugins\Text\Internal links' {

        $script:currentPageNumber = 1

        It 'outputs a see section fallback using the section number when numbering is enabled' {
            $Document = Document -Name 'T' {
                DocumentOption -EnableSectionNumbering
                Paragraph { Link -Anchor 'sec' -Text 'Details' }
                Section -Name 'Heading' -Id 'sec' { }
            }
            $pscriboDocument = $Document
            $Options = New-PScriboTextOption

            (Out-TextParagraph -Paragraph $Document.Sections[0]).Trim() | Should BeExactly 'Details (see section 1)'
        }

        It 'outputs a see title fallback for a section when numbering is disabled' {
            $Document = Document -Name 'T' {
                Paragraph { Link -Anchor 'sec' -Text 'Details' }
                Section -Name 'Heading' -Id 'sec' { }
            }
            $pscriboDocument = $Document
            $Options = New-PScriboTextOption

            (Out-TextParagraph -Paragraph $Document.Sections[0]).Trim() | Should BeExactly "Details (see 'Heading')"
        }

        It 'outputs a see title fallback for a table' {
            $Document = Document -Name 'T' {
                Paragraph { Link -Anchor 'tbl' -Text 'Details' }
                Table -Name 'Users' -Id 'tbl' -InputObject ([PSCustomObject] @{ A = 1 })
            }
            $pscriboDocument = $Document
            $Options = New-PScriboTextOption

            (Out-TextParagraph -Paragraph $Document.Sections[0]).Trim() | Should BeExactly "Details (see 'Users')"
        }

        It 'outputs only the text for an unresolved link' {
            $Document = Document -Name 'T' { Paragraph { Link -Anchor 'missing' -Text 'Nowhere' } } -WarningAction SilentlyContinue
            $pscriboDocument = $Document
            $Options = New-PScriboTextOption

            (Out-TextParagraph -Paragraph $Document.Sections[0]).Trim() | Should BeExactly 'Nowhere'
        }
    }

    Describe 'Plugins\Json\Internal links' {

        It 'outputs a structured resolved link' {
            $Document = Document -Name 'T' {
                Paragraph { Link -Anchor 'sec' -Text 'Details' }
                Section -Name 'Heading' -Id 'sec' { }
            }
            $pscriboDocument = $Document

            $result = Out-JsonParagraph -Paragraph $Document.Sections[0]

            $result[0].type | Should Be 'link'
            $result[0].target | Should Be 'sec'
            $result[0].external | Should Be $false
            $result[0].resolved | Should Be $true
        }

        It 'flags an unresolved link' {
            $Document = Document -Name 'T' { Paragraph { Link -Anchor 'missing' -Text 'Nowhere' } } -WarningAction SilentlyContinue
            $pscriboDocument = $Document

            (Out-JsonParagraph -Paragraph $Document.Sections[0])[0].resolved | Should Be $false
        }
    }
}
