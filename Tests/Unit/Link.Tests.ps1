$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent;
$testRoot  = Split-Path -Path $here -Parent;
$moduleRoot = Split-Path -Path $testRoot -Parent;
Import-Module "$moduleRoot\PScribo.psm1" -Force;

InModuleScope 'PScribo' {

    Describe 'Link' {

        $pscriboDocument = Document 'ScaffoldDocument' {}
        $script:currentPageNumber = 1

        Context 'By Named Parameter' {

            It 'throws when called outside a Paragraph block' {
                { Link -Text 'Click Here' -Uri 'https://example.com' } | Should Throw
            }

            It 'creates a PScribo.Link type within a Paragraph' {
                $result = Paragraph {
                    Link -Text 'Click Here' -Uri 'https://example.com'
                }
                $result.Sections[0].Type | Should Be 'PScribo.Link'
            }

            It 'sets the Text property' {
                $result = Paragraph {
                    Link -Text 'Click Here' -Uri 'https://example.com'
                }
                $result.Sections[0].Text | Should Be 'Click Here'
            }

            It 'sets the Uri property' {
                $result = Paragraph {
                    Link -Text 'Click Here' -Uri 'https://example.com'
                }
                $result.Sections[0].Uri | Should Be 'https://example.com'
            }

            It 'defaults NewWindow to false' {
                $result = Paragraph {
                    Link -Text 'Click Here' -Uri 'https://example.com'
                }
                $result.Sections[0].NewWindow | Should Be $false
            }

            It 'sets NewWindow to true when specified' {
                $result = Paragraph {
                    Link -Text 'Click Here' -Uri 'https://example.com' -NewWindow
                }
                $result.Sections[0].NewWindow | Should Be $true
            }

            It 'assigns a unique Name property' {
                $result = Paragraph {
                    Link -Text 'Link A' -Uri 'https://example.com/a'
                    Link -Text 'Link B' -Uri 'https://example.com/b'
                }
                $result.Sections[0].Name | Should Match '^HyperLink\d+$'
                $result.Sections[1].Name | Should Match '^HyperLink\d+$'
                $result.Sections[0].Name | Should Not Be $result.Sections[1].Name
            }

            It 'can be mixed with Text runs in a Paragraph' {
                $result = Paragraph {
                    Text 'Before'
                    Link -Text 'Click Here' -Uri 'https://example.com'
                    Text 'After'
                }
                $result.Sections.Count | Should Be 3
                $result.Sections[0].Type | Should Be 'PScribo.ParagraphRun'
                $result.Sections[1].Type | Should Be 'PScribo.Link'
                $result.Sections[2].Type | Should Be 'PScribo.ParagraphRun'
            }
        }

        Context 'By Positional Parameters' {

            It 'creates a link by positional Text parameter' {
                $result = Paragraph {
                    Link 'Click Here' -Uri 'https://example.com'
                }
                $result.Sections[0].Text | Should Be 'Click Here'
                $result.Sections[0].Uri | Should Be 'https://example.com'
            }
        }
    }
}
