function Resolve-PScriboToken
{
<#
    .SYNOPSIS
        Replaces page number tokens with their (approximated) values.
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [System.String] $InputObject
    )
    process
    {
        $tokenisedText = ConvertTo-PScriboLinkText -InputObject $InputObject
        $tokenisedText = $tokenisedText -replace
            '<!#\s?PageNumber\s?#!>', $script:currentPageNumber -replace
            '<!#\s?TotalPages\s?#!>', $Document.Properties.Pages
        return $tokenisedText
    }
}
