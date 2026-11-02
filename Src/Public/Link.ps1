function Link
{
<#
    .SYNOPSIS
        Inserts a hyperlink to an external resource, or to a section/table/anchor in the
        same document, into a paragraph.

    .DESCRIPTION
        Link returns a paragraph run, so it is used within a Paragraph script block
        alongside Text. Only http, https, ftp, mailto and tel URIs are rendered as links;
        anything else is rendered as plain text and a warning is written.

        With -Anchor the link targets the Id of a Section or Table (-Id) or of a location marked
        with Get-PScriboAnchor. Anchors are resolved when the document is rendered, so the
        target may appear later in the document. A link to an unknown anchor is rendered as
        plain text and a warning is written. Use Get-PScriboLink to link from table cells.

    .PARAMETER Text
        The text to display. For -Anchor links defaults to the section heading/table caption.

    .PARAMETER Uri
        The URI of the external resource.

    .PARAMETER Anchor
        The Id of the document section, table or anchor to link to.

    .PARAMETER NoSpace
        Do not add a space after the link.

    .PARAMETER Style
        Character style applied to the link text.

    .EXAMPLE
        Paragraph {
            Text 'Source code is on '
            Link 'GitHub' -Uri 'https://github.com/iainbrighton/PScribo'
        }
#>
    [CmdletBinding(DefaultParameterSetName = 'Uri')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Uri')]
        [Parameter(Position = 0, ParameterSetName = 'Anchor')]
        [AllowEmptyString()]
        [System.String] $Text = '',

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Uri')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(Mandatory, ParameterSetName = 'Anchor')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-PScriboAnchorId -Id $_ })]
        [System.String] $Anchor,

        [Parameter(ParameterSetName = 'Uri')]
        [Parameter(ParameterSetName = 'Anchor')]
        [System.Management.Automation.SwitchParameter] $NoSpace,

        [Parameter(ParameterSetName = 'Uri')]
        [Parameter(ParameterSetName = 'Anchor')]
        [AllowNull()]
        [System.String] $Style
    )
    process
    {
        $target = $Uri
        if ($PSCmdlet.ParameterSetName -eq 'Anchor')
        {
            $target = $Anchor
        }
        $linkDisplayName = $Text
        if ($Text.Length -gt 20)
        {
            $linkDisplayName = '{0}[..]' -f $Text.Substring(0, 16)
        }
        $targetDisplayName = $target
        if ($target.Length -gt 20)
        {
            $targetDisplayName = '{0}[..]' -f $target.Substring(0, 16)
        }
        Write-PScriboMessage -Message ($localized.ProcessingLink -f $linkDisplayName, $targetDisplayName)

        $newPScriboParagraphRunParams = @{
            Text    = New-PScriboLinkToken -Target $target -Text $Text
            NoSpace = $NoSpace
        }
        if (-not [System.String]::IsNullOrEmpty($Style))
        {
            $newPScriboParagraphRunParams['Style'] = $Style
        }
        return (New-PScriboParagraphRun @newPScriboParagraphRunParams)
    }
}
