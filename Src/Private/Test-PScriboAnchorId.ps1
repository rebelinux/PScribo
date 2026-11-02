function Test-PScriboAnchorId
{
<#
    .SYNOPSIS
        Validates a user supplied anchor Id.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String] $Id
    )
    process
    {
        if ([System.String]::IsNullOrWhiteSpace($Id) -or ($Id.Length -gt 200) -or $Id.Contains('|') -or $Id.Contains('#!>') -or ($Id -match '[\r\n]'))
        {
            throw ($localized.InvalidAnchorIdError -f $Id)
        }
        return $true
    }
}
