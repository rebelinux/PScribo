function Out-JsonParagraph
{
<#
    .SYNOPSIS
        Output formatted paragraph run.
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $Paragraph
    )
    begin
    {
        ## Initializing string object
        [System.Text.StringBuilder] $paragraphBuilder = New-Object -TypeName 'System.Text.StringBuilder'
    }
    process
    {
        ## Paragraphs containing links are output as a list of text/link objects
        $items = New-Object -TypeName 'System.Collections.ArrayList'
        $hasLinks = $false

        foreach ($paragraphRun in $Paragraph.Sections)
        {
            $addSpace = ($paragraphRun.IsParagraphRunEnd -eq $false) -and ($paragraphRun.NoSpace -eq $false)
            $runSegments = @(Get-PScriboLinkSegment -Text $paragraphRun.Text)
            foreach ($segment in $runSegments)
            {
                switch ($segment.Kind)
                {
                    'Text'
                    {
                        [ref] $null = $items.Add([ordered] @{ type = 'text'; text = (Resolve-PScriboToken -InputObject $segment.Text) })
                    }
                    'Link'
                    {
                        $hasLinks = $true
                        $segment = Resolve-PScriboLinkSegment -Segment $segment
                        [ref] $null = $items.Add([ordered] @{
                            type     = 'link'
                            text     = Get-PScriboLinkDisplayText -Segment $segment
                            target   = $segment.Target
                            external = $segment.IsExternal
                            resolved = $segment.IsResolved
                        })
                    }
                    'Anchor'
                    {
                        $hasLinks = $true
                        [ref] $null = $items.Add([ordered] @{ type = 'anchor'; id = $segment.Id })
                    }
                }
            }

            if ($addSpace)
            {
                $lastItem = if ($items.Count -gt 0) { $items[$items.Count - 1] } else { $null }
                if (($null -ne $lastItem) -and ($lastItem['type'] -eq 'text'))
                {
                    $lastItem['text'] = '{0} ' -f $lastItem['text']
                }
                else
                {
                    [ref] $null = $items.Add([ordered] @{ type = 'text'; text = ' ' })
                }
            }
        }

        if ($hasLinks)
        {
            return ,$items.ToArray()
        }

        foreach ($item in $items)
        {
            [ref] $null = $paragraphBuilder.Append($item['text'])
        }
        return $paragraphBuilder.ToString()
    }
}
