function New-WordBookmark
{
<#
    .SYNOPSIS
        Creates a matching w:bookmarkStart/w:bookmarkEnd pair for an anchor Id.

    .DESCRIPTION
        Returns $null when the anchor is not registered, has already been emitted (duplicate
        bookmark names corrupt the document) or is in a header/footer part. Bookmark ids are unique
        within the document.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String] $AnchorId,

        [Parameter(Mandatory)]
        [System.Xml.XmlDocument] $XmlDocument
    )
    process
    {
        $inHeaderFooter = [System.Boolean] (Get-Variable -Name pscriboWordInHeaderFooter -Scope Script -ValueOnly -ErrorAction SilentlyContinue)
        $entry = Get-PScriboAnchorEntry -Id $AnchorId
        if ($inHeaderFooter -or ($null -eq $entry))
        {
            return $null
        }

        $bookmarks = Get-Variable -Name pscriboWordBookmarks -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($null -eq $bookmarks)
        {
            $bookmarks = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
            $script:pscriboWordBookmarks = $bookmarks
        }
        if (-not $bookmarks.Add($entry.Name))
        {
            return $null
        }
        $script:pscriboWordBookmarkId = [System.Int32] (Get-Variable -Name pscriboWordBookmarkId -Scope Script -ValueOnly -ErrorAction SilentlyContinue) + 1

        $xmlns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
        $start = $XmlDocument.CreateElement('w', 'bookmarkStart', $xmlns)
        [ref] $null = $start.SetAttribute('id', $xmlns, $script:pscriboWordBookmarkId)
        [ref] $null = $start.SetAttribute('name', $xmlns, $entry.Name)
        $end = $XmlDocument.CreateElement('w', 'bookmarkEnd', $xmlns)
        [ref] $null = $end.SetAttribute('id', $xmlns, $script:pscriboWordBookmarkId)

        return [PSCustomObject] @{ Start = $start; End = $end }
    }
}
