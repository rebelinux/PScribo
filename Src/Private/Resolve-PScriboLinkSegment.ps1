function Resolve-PScriboLinkSegment
{
<#
    .SYNOPSIS
        Adds resolution details (IsResolved, AnchorName) to a link segment.

    .NOTES
        External links are resolved when their URI scheme is permitted.
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.PSObject] $Segment
    )
    process
    {
        $isResolved = $false
        $anchorName = $null
        if ($Segment.IsExternal)
        {
            $isResolved = Test-PScriboLinkUri -Uri $Segment.Target
        }
        else
        {
            $entry = Get-PScriboAnchorEntry -Id $Segment.Target
            if ($null -ne $entry)
            {
                $isResolved = $true
                $anchorName = $entry.Name
            }
        }

        return [PSCustomObject] @{
            Kind        = $Segment.Kind
            Text        = $Segment.Text
            Target      = $Segment.Target
            Id          = $Segment.Id
            IsExternal  = $Segment.IsExternal
            IsResolved  = $isResolved
            AnchorName  = $anchorName
        }
    }
}
