function Test-PScriboLinkUri
{
<#
    .SYNOPSIS
        Returns $true when a link target is an external URI using a permitted scheme.

    .NOTES
        Only http, https, mailto, tel and ftp links are rendered. This stops generated
        documents from carrying script (javascript:/data:) or local file links.
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [System.String] $Uri
    )
    process
    {
        return ($Uri -match '^(https?|ftp)://[^\s]+$') -or ($Uri -match '^(mailto|tel):[^\s]+$')
    }
}
