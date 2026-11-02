function Get-PScriboAnchorEntry
{
<#
    .SYNOPSIS
        Returns the document anchor registry entry (Name, Type, Title, Number) for an anchor Id, or $null.

    .NOTES
        The registry is built by Initialize-PScriboLink when the document is created, so
        entries are available to every plugin regardless of where the anchor is defined.
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String] $Id
    )
    process
    {
        if ([System.String]::IsNullOrEmpty($Id))
        {
            return $null
        }
        $currentDocument = Get-Variable -Name Document -ErrorAction SilentlyContinue -ValueOnly
        if (($null -eq $currentDocument) -or ($null -eq $currentDocument.Properties) -or (-not $currentDocument.Properties.ContainsKey('Anchors')))
        {
            return $null
        }
        $anchors = $currentDocument.Properties['Anchors']
        if ($anchors.ContainsKey($Id))
        {
            return $anchors[$Id]
        }
        return $null
    }
}
