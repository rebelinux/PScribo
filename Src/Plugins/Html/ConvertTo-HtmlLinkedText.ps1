function ConvertTo-HtmlLinkedText
{
<#
    .SYNOPSIS
        Html encodes text, rendering link and anchor tokens as <a>/<span> elements.

    .NOTES
        Text is encoded per segment so that tokens are parsed before encoding. Only
        permitted URI schemes are rendered as links (see Test-PScriboLinkUri).
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [System.String] $Text
    )
    process
    {
        $builder = New-Object -TypeName 'System.Text.StringBuilder'
        foreach ($segment in @(Get-PScriboLinkSegment -Text $Text))
        {
            switch ($segment.Kind)
            {
                'Text'
                {
                    $resolvedText = Resolve-PScriboToken -InputObject $segment.Text
                    $encodedText = [System.Net.WebUtility]::HtmlEncode($resolvedText)
                    [ref] $null = $builder.Append($encodedText.Replace([System.Environment]::NewLine, '<br />'))
                }
                'Anchor'
                {
                    $anchorEntry = Get-PScriboAnchorEntry -Id $segment.Id
                    if ($null -ne $anchorEntry)
                    {
                        [ref] $null = $builder.AppendFormat('<span id="{0}"></span>', $anchorEntry.Name)
                    }
                }
                'Link'
                {
                    $segment = Resolve-PScriboLinkSegment -Segment $segment
                    $encodedText = [System.Net.WebUtility]::HtmlEncode((Get-PScriboLinkDisplayText -Segment $segment))
                    if ($segment.IsResolved -and $segment.IsExternal)
                    {
                        $encodedUri = [System.Net.WebUtility]::HtmlEncode($segment.Target)
                        [ref] $null = $builder.AppendFormat('<a href="{0}" target="_blank" rel="noopener">{1}</a>', $encodedUri, $encodedText)
                    }
                    elseif ($segment.IsResolved)
                    {
                        [ref] $null = $builder.AppendFormat('<a href="#{0}">{1}</a>', $segment.AnchorName, $encodedText)
                    }
                    else
                    {
                        [ref] $null = $builder.Append($encodedText)
                    }
                }
            }
        }
        return $builder.ToString()
    }
}
