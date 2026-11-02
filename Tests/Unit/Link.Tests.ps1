$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$testRoot  = Split-Path -Path $here -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Link' {

        $pscriboDocument = Document -Name 'Test' -ScriptBlock { }

        It 'returns a paragraph run that carries a link token' {
            $run = Link 'GitHub' -Uri 'https://github.com'

            $run.Type | Should Be 'PScribo.ParagraphRun'
            $run.Text | Should BeExactly '<!#Link:https://github.com|GitHub#!>'
        }

        It 'accepts positional text and uri' {
            (Link 'GitHub' 'https://github.com').Text | Should BeExactly '<!#Link:https://github.com|GitHub#!>'
        }

        It 'does not throw when text is long and the uri is short (WIP regression)' {
            { Link 'a very long link text that exceeds twenty characters' -Uri 'https://a.b' } | Should Not Throw
        }

        It 'can be used inside a paragraph script block' {
            $paragraph = Paragraph { Text 'See '; Link 'GitHub' -Uri 'https://github.com' }

            $paragraph.Sections.Count | Should Be 2
            $paragraph.Sections[1].Text | Should Match '^<!#Link:'
            $paragraph.Sections[1].IsParagraphRunEnd | Should Be $true
        }

        It 'passes -NoSpace and -Style to the run' {
            $run = Link 'x' -Uri 'https://github.com' -NoSpace -Style 'Bold'

            $run.NoSpace | Should Be $true
            $run.Style | Should Be 'Bold'
            $run.HasStyle | Should Be $true
        }

        It 'escapes the token separator in the uri' {
            (Link 'x' -Uri 'https://a.b/?q=1|2').Text | Should BeExactly '<!#Link:https://a.b/?q=1%7C2|x#!>'
        }
    }

    Describe 'Get-PScriboLinkSegment' {

        It 'returns a single text segment when there are no tokens' {
            $segments = @(Get-PScriboLinkSegment -Text 'Just text')

            $segments.Count | Should Be 1
            $segments[0].Kind | Should Be 'Text'
            $segments[0].Text | Should Be 'Just text'
        }

        It 'returns a single empty text segment for an empty string' {
            $segments = @(Get-PScriboLinkSegment -Text '')

            $segments.Count | Should Be 1
            $segments[0].Kind | Should Be 'Text'
        }

        It 'splits text around a link' {
            $segments = @(Get-PScriboLinkSegment -Text 'a <!#Link:https://x.y|Link text#!> b')

            $segments.Count | Should Be 3
            $segments[0].Text | Should Be 'a '
            $segments[1].Kind | Should Be 'Link'
            $segments[1].Text | Should Be 'Link text'
            $segments[1].Target | Should Be 'https://x.y'
            $segments[1].IsExternal | Should Be $true
            $segments[2].Text | Should Be ' b'
        }

        It 'treats a target without a scheme as an internal link' {
            $segment = @(Get-PScriboLinkSegment -Text '<!#Link:Policy_A|A#!>')[0]

            $segment.IsExternal | Should Be $false
            $segment.Target | Should Be 'Policy_A'
        }

        It 'does not treat javascript: as an internal or permitted link' {
            $segment = @(Get-PScriboLinkSegment -Text '<!#Link:javascript:alert(1)|x#!>')[0]

            $segment.IsExternal | Should Be $false
            Test-PScriboLinkUri -Uri 'javascript:alert(1)' | Should Be $false
        }

        It 'returns adjacent links without text between them' {
            $segments = @(Get-PScriboLinkSegment -Text '<!#Link:A|1#!><!#Link:B|2#!>')

            $segments.Count | Should Be 2
            $segments[0].Target | Should Be 'A'
            $segments[1].Target | Should Be 'B'
        }

        It 'allows a link without display text' {
            $segment = @(Get-PScriboLinkSegment -Text '<!#Link:Policy_A#!>')[0]

            $segment.Text | Should Be ''
            (Get-PScriboLinkDisplayText -Segment $segment) | Should Be 'Policy_A'
        }

        It 'keeps pipes and hashes inside the display text' {
            $segment = @(Get-PScriboLinkSegment -Text '<!#Link:A|x | y # z#!>')[0]

            $segment.Text | Should Be 'x | y # z'
        }

        It 'parses anchors' {
            $segment = @(Get-PScriboLinkSegment -Text 'row<!#Anchor:Row_1#!>')[1]

            $segment.Kind | Should Be 'Anchor'
            $segment.Id | Should Be 'Row_1'
        }

        It 'leaves other tokens (PageNumber) untouched' {
            $segments = @(Get-PScriboLinkSegment -Text 'Page <!# PageNumber #!>')

            $segments.Count | Should Be 1
            $segments[0].Kind | Should Be 'Text'
        }
    }

    Describe 'Test-PScriboLinkUri' {

        It 'permits <uri>' -TestCases @(
            @{ uri = 'https://example.com/a?b=c' }
            @{ uri = 'http://example.com' }
            @{ uri = 'mailto:someone@example.com' }
            @{ uri = 'ftp://example.com/file' }
        ) {
            param ($uri)
            Test-PScriboLinkUri -Uri $uri | Should Be $true
        }

        It 'rejects <uri>' -TestCases @(
            @{ uri = 'javascript://alert(1)' }
            @{ uri = 'data:text/html,hi' }
            @{ uri = 'file://c:/windows' }
            @{ uri = 'https://has space.com' }
            @{ uri = '' }
        ) {
            param ($uri)
            Test-PScriboLinkUri -Uri $uri | Should Be $false
        }
    }

    Describe 'ConvertTo-PScriboLinkText' {

        It 'renders an external link as text and uri' {
            ConvertTo-PScriboLinkText -InputObject 'See <!#Link:https://x.y|X#!>.' | Should BeExactly 'See X > (https://x.y).'
        }

        It 'renders a link with a rejected uri as plain text' {
            ConvertTo-PScriboLinkText -InputObject '<!#Link:javascript://x|X#!>' | Should BeExactly 'X'
        }

        It 'returns text without tokens unchanged' {
            ConvertTo-PScriboLinkText -InputObject 'plain' | Should BeExactly 'plain'
        }
    }
}
