[CmdletBinding()]
param (
    [System.String[]] $Format = 'Word',
    [System.String] $Path = '~\Desktop',
    [System.Management.Automation.SwitchParameter] $PassThru
)

Import-Module PScribo -Force -Verbose:$false

$example45 = Document -Name 'PScribo Example 45' {

    <#
        Link command is used to create inline hyperlinks in paragraphs. The '-Uri' parameter can be used to specify how the link will open.
        The '-Text' parameter can be used to specify the text that will be displayed for the link.
    #>
    Paragraph {
        Text 'You can find the PScribo documentation examples'
        Link -Text 'Here' -Uri 'https://github.com/iainbrighton/PScribo/tree/dev/Examples'
    }
    <#
        The '-NewWindow' parameter can be used to specify that the link will open in a new window. 
    #>

    Paragraph {
        Text 'You can find the PScribo documentation examples open in a new window'
        Link -Text 'Here' -Uri 'https://github.com/iainbrighton/PScribo/tree/dev/Examples' -NewWindow
    }

}
$example45 | Export-Document -Path $Path -Format $Format -PassThru:$PassThru
