function Get-PScriboLinkSegment
{
<#
    .SYNOPSIS
        Splits a string into text, link and anchor segments.

    .DESCRIPTION
        Links and anchors are carried inside strings as tokens, so they work in paragraph
        runs and table cells alike:

            <!#Link:Target|Display text#!>   (Target is a URI or an anchor Id)
            <!#Link:Target#!>                (display text is resolved at output time)
            <!#Anchor:Id#!>                  (an invisible anchor, i.e. a table row target)

        A string without tokens returns a single 'Text' segment.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [System.String] $Text
    )
    process
    {
        if ([System.String]::IsNullOrEmpty($Text) -or ($Text.IndexOf('<!#') -lt 0))
        {
            return [PSCustomObject] @{ Kind = 'Text'; Text = $Text; Target = $null; Id = $null; IsExternal = $false }
        }

        $tokenPattern = '<!#(?:Link:(?<target>.*?)(?:\|(?<text>.*?))?|Anchor:(?<id>.*?))#!>'
        $regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
        $segments = New-Object -TypeName 'System.Collections.ArrayList'
        $position = 0

        foreach ($match in [System.Text.RegularExpressions.Regex]::Matches($Text, $tokenPattern, $regexOptions))
        {
            if ($match.Index -gt $position)
            {
                $literal = $Text.Substring($position, $match.Index - $position)
                [ref] $null = $segments.Add([PSCustomObject] @{ Kind = 'Text'; Text = $literal; Target = $null; Id = $null; IsExternal = $false })
            }

            if ($match.Groups['id'].Success)
            {
                $anchorId = $match.Groups['id'].Value.Trim()
                [ref] $null = $segments.Add([PSCustomObject] @{ Kind = 'Anchor'; Text = $null; Target = $null; Id = $anchorId; IsExternal = $false })
            }
            else
            {
                $target = $match.Groups['target'].Value.Trim()
                $linkText = ''
                if ($match.Groups['text'].Success)
                {
                    $linkText = $match.Groups['text'].Value
                }
                $isExternal = $target -match '^[A-Za-z][A-Za-z0-9+.-]*://' -or $target -match '^(mailto|tel):'
                [ref] $null = $segments.Add([PSCustomObject] @{ Kind = 'Link'; Text = $linkText; Target = $target; Id = $null; IsExternal = $isExternal })
            }
            $position = $match.Index + $match.Length
        }

        if ($position -lt $Text.Length)
        {
            [ref] $null = $segments.Add([PSCustomObject] @{ Kind = 'Text'; Text = $Text.Substring($position); Target = $null; Id = $null; IsExternal = $false })
        }
        if ($segments.Count -eq 0)
        {
            [ref] $null = $segments.Add([PSCustomObject] @{ Kind = 'Text'; Text = $Text; Target = $null; Id = $null; IsExternal = $false })
        }

        return $segments.ToArray()
    }
}
