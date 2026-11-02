$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$pluginsRoot  = Split-Path -Path $here -Parent;
$testRoot  = Split-Path -Path $pluginsRoot -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Plugins\Html\Anchors' {

        $script:currentPageNumber = 1

        It 'adds an id to a section heading with an Id' {
            $Document = Document -Name 'T' { Section -Name 'Heading' -Id 'sec-1' { } }
            $pscriboDocument = $Document

            $html = Out-HtmlSection -Section $Document.Sections[0]

            $html | Should Match '<h1 class="[^"]*" id="sec_1_[0-9a-f]{8}">'
        }

        It 'does not add an id to a section without an Id' {
            $Document = Document -Name 'T' { Section -Name 'Heading' { } }
            $pscriboDocument = $Document

            Out-HtmlSection -Section $Document.Sections[0] | Should Not Match ' id='
        }

        It 'adds an id to a table with an Id' {
            $Document = Document -Name 'T' { Table -Name 'Tbl' -Id 'tbl1' -InputObject ([PSCustomObject] @{ A = 1 }) }
            $pscriboDocument = $Document

            Out-HtmlTable -Table $Document.Sections[0] | Should Match '<table class="[^"]*" id="tbl1"'
        }

        It 'outputs an empty span for an anchor token in a table cell' {
            $Document = Document -Name 'T' { Table -Name 'Tbl' -InputObject ([PSCustomObject] @{ A = '{0}Row' -f (Get-PScriboAnchor -Id 'row1') }) }
            $pscriboDocument = $Document

            Out-HtmlTable -Table $Document.Sections[0] | Should Match '<td><span id="row1"></span>Row</td>'
        }
    }

    Describe 'Plugins\Json\Anchors' {

        It 'adds ids to sections and tables that have one' {
            $Document = Document -Name 'T' {
                Section -Name 'Heading' -Id 'sec-1' { Table -Name 'Tbl' -Id 'tbl-1' -InputObject ([PSCustomObject] @{ A = 1 }, [PSCustomObject] @{ A = 2 }) }
            }
            $pscriboDocument = $Document

            $json = Out-JsonSection -Section $Document.Sections[0]

            $json['id'] | Should Be 'sec-1'
            $json['table1Id'] | Should Be 'tbl-1'
        }

        It 'does not add ids when none are supplied' {
            $Document = Document -Name 'T' { Section -Name 'Heading' { Paragraph 'x' } }
            $pscriboDocument = $Document

            (Out-JsonSection -Section $Document.Sections[0]).Contains('id') | Should Be $false
        }
    }
}
