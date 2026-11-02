[CmdletBinding()]
param (
    [System.String[]] $Format = 'Word',
    [System.String] $Path = '~\Desktop',
    [System.Management.Automation.SwitchParameter] $PassThru
)

Import-Module PScribo -Force -Verbose:$false

$example45 = Document -Name 'PScribo Example 45' {

    <#
        Links can point to an external resource (-Uri) or to another part of the same document
        (-Anchor). Internal links are resolved when the document is rendered, so they can refer to
        sections or tables that are defined later in the document.
    #>
    Paragraph -Style Heading1 'Links'

    Paragraph {
        Text 'PScribo is hosted on'
        Link 'GitHub' -Uri 'https://github.com/iainbrighton/PScribo' -NoSpace
        Text '.'
    }

    Paragraph {
        Text 'Jump to the'
        Link -Anchor 'details' -NoSpace
        Text 'section or see the'
        Link -Anchor 'teams' -Text 'teams table' -NoSpace
        Text '.'
    }

    <#
        Table cells cannot use Link, so use Get-PScriboLink to build the link text and
        Get-PScriboAnchor to mark a row that can be linked to.
    #>
    $teams = 'Sales', 'Support' | ForEach-Object {
        [PSCustomObject] @{
            Team    = '{0}{1}' -f (Get-PScriboAnchor -Id "team-$_"), $_
            Details = Get-PScriboLink -Anchor 'details' -Text 'See details'
        }
    }
    Table -Name 'Teams' -Id 'teams' -InputObject $teams

    Section -Name 'Details' -Id 'details' {
        Paragraph {
            Text 'Back to'
            Link -Anchor 'team-Support' -Text 'the Support row' -NoSpace
            Text '.'
        }
    }
}
$example45 | Export-Document -Path $Path -Format $Format -PassThru:$PassThru
