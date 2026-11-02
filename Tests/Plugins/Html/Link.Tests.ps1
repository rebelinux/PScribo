$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginsRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginsRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Html\Links (external)' {

        $Document = Document -Name 'Test' -ScriptBlock { }
        $pscriboDocument = $Document
        $script:currentPageNumber = 1

        It 'outputs an anchor for an external link' {
            $result = Paragraph { Text 'See'; Link 'GitHub' -Uri 'https://github.com' } | Out-HtmlParagraph

            $result | Should BeExactly '<div>See <a href="https://github.com" target="_blank" rel="noopener">GitHub</a></div>'
        }

        It 'html encodes the display text and the uri' {
            $result = Paragraph { Link 'A <b> & B' -Uri 'https://example.com/?a=1&b="2"' } | Out-HtmlParagraph

            $result | Should Match 'href="https://example.com/\?a=1&amp;b=&quot;2&quot;"'
            $result | Should Match '>A &lt;b&gt; &amp; B</a>'
        }

        It 'does not render a javascript: link' {
            $result = Paragraph { Link 'Click' -Uri 'javascript://alert(1)' } | Out-HtmlParagraph

            $result | Should BeExactly '<div>Click</div>'
        }

        It 'does not render a link with an unlisted scheme in a table cell' {
            $table = Table -Name 'T' -InputObject ([PSCustomObject] @{ Name = 'x'; Doc = '<!#Link:data://x|Click#!>' })

            $result = Out-HtmlTable -Table $table

            $result | Should Not Match '<a '
            $result | Should Match '<td>Click</td>'
        }

        It 'outputs an anchor in a table cell' {
            $table = Table -Name 'T' -InputObject ([PSCustomObject] @{ Name = 'x'; Doc = 'See <!#Link:https://github.com|GitHub#!> now' })

            $result = Out-HtmlTable -Table $table

            $result | Should Match '<td>See <a href="https://github.com" target="_blank" rel="noopener">GitHub</a> now</td>'
        }

        It 'still encodes text without tokens' {
            (Paragraph 'Embedded <br />' | Out-HtmlParagraph) | Should BeExactly '<div>Embedded &lt;br /&gt;</div>'
        }
    }
}
