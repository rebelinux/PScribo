function Out-JsonTable
{
<#
    .SYNOPSIS
        Output formatted Json table.
#>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.PSObject] $Table
    )
    begin
    {
        ## Initializing table object
        $tableBuilder = [System.Collections.ArrayList]::new()
    }
    process
    {
        if ($Table.HasCaption)
        {
            [ref] $null = $tableBuilder.Add((Get-JsonTableCaption -Table $Table))
        }

        $rows = @($Table.Rows | Select-Object -Property * -ExcludeProperty '*__Style')

        ## Rows are copies at this point, so replace link tokens with their text
        foreach ($row in $rows)
        {
            foreach ($property in $row.PSObject.Properties)
            {
                if ($property.Value -is [System.String])
                {
                    $property.Value = ConvertTo-PScriboLinkText -InputObject $property.Value
                }
            }
        }
        ## Keep the existing output shape: a single row is not wrapped in an array
        if ($rows.Count -eq 1)
        {
            $rows = $rows[0]
        }
        elseif ($rows.Count -eq 0)
        {
            $rows = $null
        }
        [ref] $null = $tableBuilder.Add($rows)

        return $tableBuilder
    }
}
