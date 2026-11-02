function Resolve-PScriboAnchorName
{
<#
    .SYNOPSIS
        Converts a user supplied anchor Id into a name that is valid as a Word bookmark and Html id.

    .DESCRIPTION
        Names contain only letters, digits and underscores, start with a letter and are at most
        40 characters long. Ids that need changing (invalid characters, too long) get a deterministic
        suffix derived from a SHA256 hash of the original Id. Collisions with names already in use
        (compared case-insensitively) get a numeric suffix.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Id,

        ## Names that are already in use
        [Parameter()]
        [System.Collections.Generic.HashSet[System.String]] $ExistingName
    )
    process
    {
        $maxLength = 40
        $name = [System.Text.RegularExpressions.Regex]::Replace($Id, '[^A-Za-z0-9_]', '_')
        if ($name -notmatch '^[A-Za-z]')
        {
            $name = 'A_{0}' -f $name
        }

        if (($name -cne $Id) -or ($name.Length -gt 34))
        {
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            try
            {
                $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Id))
            }
            finally
            {
                $sha256.Dispose()
            }
            $hash = ([System.BitConverter]::ToString($hashBytes) -replace '-', '').Substring(0, 8).ToLowerInvariant()
            if ($name.Length -gt 28)
            {
                $name = $name.Substring(0, 28)
            }
            $name = '{0}_{1}' -f $name, $hash
        }

        if ($null -ne $ExistingName)
        {
            $baseName = $name
            $counter = 1
            while ($ExistingName.Contains($name))
            {
                $counter++
                $suffix = '_{0}' -f $counter
                $name = '{0}{1}' -f $baseName.Substring(0, [System.Math]::Min($baseName.Length, ($maxLength - $suffix.Length))), $suffix
            }
        }

        return $name
    }
}
