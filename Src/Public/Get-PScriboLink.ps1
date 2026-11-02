function Get-PScriboLink
{
<#
    .SYNOPSIS
        Returns a link token that can be embedded in table cell or paragraph text.

    .DESCRIPTION
        Use Get-PScriboLink where Link cannot be used, for example in the property values of
        objects passed to Table. The token is resolved when the document is rendered.

        This function is also a feature marker: callers that must also run against PScribo
        versions without link support can test for it with Get-Command Get-PScriboLink.

    .PARAMETER Text
        The text to display. For -Anchor links defaults to the section heading/table caption.

    .PARAMETER Uri
        The URI of an external resource (http, https, ftp, mailto or tel).

    .PARAMETER Anchor
        The Id of the document section, table or anchor to link to.

    .EXAMPLE
        Table -Name 'Teams' -InputObject ([PSCustomObject] @{ Team = Get-PScriboLink -Anchor 'team-sales' -Text 'Sales' })

    .EXAMPLE
        if (Get-Command -Name Get-PScriboLink -ErrorAction SilentlyContinue) { Get-PScriboLink -Anchor $id -Text $name } else { $name }
#>
    [CmdletBinding(DefaultParameterSetName = 'Anchor')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'Anchor')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-PScriboAnchorId -Id $_ })]
        [System.String] $Anchor,

        [Parameter(Mandatory, ParameterSetName = 'Uri')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [System.String] $Text = ''
    )
    process
    {
        $target = $Uri
        if ($PSCmdlet.ParameterSetName -eq 'Anchor')
        {
            $target = $Anchor
        }
        return (New-PScriboLinkToken -Target $target -Text $Text)
    }
}
