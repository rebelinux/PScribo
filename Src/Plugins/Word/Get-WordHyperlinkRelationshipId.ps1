function Get-WordHyperlinkRelationshipId
{
<#
    .SYNOPSIS
        Returns the document relationship Id for an external hyperlink, registering it if required.

    .NOTES
        Relationships are collected during document generation (Get-WordDocument) and
        created on the document part by Out-WordDocument.
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri
    )
    process
    {
        if (-not (Get-Variable -Name pscriboWordHyperlinks -Scope Script -ErrorAction SilentlyContinue))
        {
            $script:pscriboWordHyperlinks = New-Object -TypeName 'System.Collections.Specialized.OrderedDictionary'
        }

        if (-not $script:pscriboWordHyperlinks.Contains($Uri))
        {
            $script:pscriboWordHyperlinks[$Uri] = 'rIdLink{0}' -f ($script:pscriboWordHyperlinks.Count + 1)
        }
        return $script:pscriboWordHyperlinks[$Uri]
    }
}
