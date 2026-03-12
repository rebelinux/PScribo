function Get-PScriboLink
{
<#
    .SYNOPSIS
        Retrieves PScribo.Link objects from a document/section hierarchy.
#>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.PSObject[]] $Section
    )
    process
    {
        foreach ($subSection in $Section)
        {
            switch ($subSection.Type)
            {
                'PScribo.Paragraph'
                {
                    foreach ($run in $subSection.Sections)
                    {
                        if ($run.Type -eq 'PScribo.Link')
                        {
                            Write-Output -InputObject $run
                        }
                    }
                }
                'PScribo.Section'
                {
                    if ($subSection.Sections.Count -gt 0)
                    {
                        ## Recursively search subsections
                        Get-PScriboLink -Section $subSection.Sections
                    }
                }
            }
        }
    }
}
