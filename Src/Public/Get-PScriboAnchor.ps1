function Get-PScriboAnchor
{
<#
    .SYNOPSIS
        Returns an anchor token that marks a location (e.g. a table row) that can be linked to.

    .DESCRIPTION
        Embed the returned string in a table cell or paragraph text. Anchors are resolved when the
        document is rendered, so links may refer to an anchor defined later in the document.
        The token is not visible in the output.

    .PARAMETER Id
        The anchor Id. Must be unique within the document. Use the same Id with Link -Anchor
        or Get-PScriboLink -Anchor to link to this location.

    .EXAMPLE
        $rows = $teams | ForEach-Object {
            [PSCustomObject] @{ Name = '{0}{1}' -f (Get-PScriboAnchor -Id "team-$($_.Id)"), $_.Name }
        }
        Table -Name 'Teams' -InputObject $rows
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-PScriboAnchorId -Id $_ })]
        [System.String] $Id
    )
    process
    {
        return (New-PScriboLinkToken -Anchor $Id)
    }
}
