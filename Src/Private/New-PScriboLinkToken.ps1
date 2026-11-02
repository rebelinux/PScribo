function New-PScriboLinkToken
{
<#
    .SYNOPSIS
        Returns the string token for a link or an anchor.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'Link')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Target,

        [Parameter(ParameterSetName = 'Link')]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String] $Text,

        [Parameter(Mandatory, ParameterSetName = 'Anchor')]
        [ValidateNotNullOrEmpty()]
        [System.String] $Anchor
    )
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Anchor')
        {
            return '<!#Anchor:{0}#!>' -f $Anchor.Replace('#!>', '# !>')
        }

        $safeTarget = $Target.Replace('|', '%7C').Replace('#!>', '# !>')
        if ([System.String]::IsNullOrEmpty($Text))
        {
            return '<!#Link:{0}#!>' -f $safeTarget
        }
        return '<!#Link:{0}|{1}#!>' -f $safeTarget, $Text.Replace('#!>', '# !>')
    }
}
