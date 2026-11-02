function Initialize-PScriboLink
{
<#
    .SYNOPSIS
        Scans a completed document for links and validates them.

    .DESCRIPTION
        Links are resolved when the document is rendered, so forward references are
        supported. This scan runs once the document has been built and records the
        number of links (Properties['Links']) and warns about links that cannot be
        rendered as links.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSObject] $PScriboDocument
    )
    process
    {
        $anchors = New-Object -TypeName 'System.Collections.Generic.Dictionary[System.String,System.Object]' -ArgumentList ([System.StringComparer]::Ordinal)
        $usedNames = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
        $registerAnchor = {
            param ($Id, $Type, $Title, $Number)
            if ([System.String]::IsNullOrEmpty($Id))
            {
                return
            }
            if ($anchors.ContainsKey($Id))
            {
                Write-PScriboMessage -Message ($localized.DuplicateAnchorIdWarning -f $Id) -IsWarning
                return
            }
            $name = Resolve-PScriboAnchorName -Id $Id -ExistingName $usedNames
            [ref] $null = $usedNames.Add($name)
            $anchors[$Id] = [PSCustomObject] @{ Id = $Id; Name = $name; Type = $Type; Title = $Title; Number = $Number }
        }

        $texts = New-Object -TypeName 'System.Collections.ArrayList'
        $stack = New-Object -TypeName 'System.Collections.Stack'
        for ($i = $PScriboDocument.Sections.Count - 1; $i -ge 0; $i--)
        {
            $stack.Push($PScriboDocument.Sections[$i])
        }

        while ($stack.Count -gt 0)
        {
            $item = $stack.Pop()
            switch ($item.Type)
            {
                'PScribo.Section'
                {
                    & $registerAnchor $item.LinkId 'Section' $item.Name $item.Number
                    for ($i = $item.Sections.Count - 1; $i -ge 0; $i--)
                    {
                        $stack.Push($item.Sections[$i])
                    }
                }
                'PScribo.Paragraph'
                {
                    foreach ($paragraphRun in $item.Sections)
                    {
                        [ref] $null = $texts.Add($paragraphRun.Text)
                    }
                }
                'PScribo.Table'
                {
                    $tableTitle = if ($item.HasCaption) { $item.Caption } else { $item.Name }
                    & $registerAnchor $item.LinkId 'Table' $tableTitle $null
                    foreach ($row in $item.Rows)
                    {
                        foreach ($property in $row.PSObject.Properties)
                        {
                            if ($property.Name -like '*__Style')
                            {
                                continue
                            }
                            foreach ($value in @($property.Value))
                            {
                                if ($value -is [System.String])
                                {
                                    [ref] $null = $texts.Add($value)
                                }
                            }
                        }
                    }
                }
            }
        }

        $linkCount = 0
        $linkSegments = New-Object -TypeName 'System.Collections.ArrayList'
        foreach ($text in $texts)
        {
            if (($null -eq $text) -or ($text.IndexOf('<!#') -lt 0))
            {
                continue
            }
            foreach ($segment in @(Get-PScriboLinkSegment -Text $text))
            {
                if ($segment.Kind -eq 'Anchor')
                {
                    & $registerAnchor $segment.Id 'Anchor' $null $null
                }
                elseif ($segment.Kind -eq 'Link')
                {
                    [ref] $null = $linkSegments.Add($segment)
                }
            }
        }

        ## Anchors can be defined after the links that refer to them, so validate once all are registered
        $warnedTargets = New-Object -TypeName 'System.Collections.Generic.HashSet[System.String]'
        foreach ($segment in $linkSegments)
        {
            $linkCount++
            if ($segment.IsExternal)
            {
                if ((-not (Test-PScriboLinkUri -Uri $segment.Target)) -and $warnedTargets.Add($segment.Target))
                {
                    Write-PScriboMessage -Message ($localized.UnsupportedLinkUriWarning -f $segment.Target) -IsWarning
                }
            }
            elseif ((-not $anchors.ContainsKey($segment.Target)) -and $warnedTargets.Add($segment.Target))
            {
                Write-PScriboMessage -Message ($localized.UnresolvedLinkWarning -f $segment.Target) -IsWarning
            }
        }
        $PScriboDocument.Properties['Links'] = $linkCount
        $PScriboDocument.Properties['Anchors'] = $anchors
    }
}
