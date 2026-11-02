function Get-PScriboLinkDisplayText
{
<#
    .SYNOPSIS
        Returns the text to display for a link segment.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.PSObject] $Segment
    )
    process
    {
        if (-not [System.String]::IsNullOrEmpty($Segment.Text))
        {
            return $Segment.Text
        }
        if (-not $Segment.IsExternal)
        {
            $entry = Get-PScriboAnchorEntry -Id $Segment.Target
            if (($null -ne $entry) -and (-not [System.String]::IsNullOrEmpty($entry.Title)))
            {
                return $entry.Title
            }
        }
        return $Segment.Target
    }
}
