function New-PScriboLink
{
<#
    .SYNOPSIS
        Initializes a new PScribo hyperlink (link) paragraph run object.

    .NOTES
        This is an internal function and should not be called directly.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions','')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [AllowEmptyString()]
        [System.String] $Text,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $NewWindow,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $NoSpace
    )
    process
    {
        $linkNumber = [System.Int32] $pscriboDocument.Properties['Links']++
        $pscriboLink = [PSCustomObject] @{
            Type              = 'PScribo.Link'
            Text              = $Text
            Uri               = $Uri
            NewWindow         = $NewWindow.ToBool()
            NoSpace           = $NoSpace
            IsParagraphRunEnd = $false
            Name              = 'HyperLink{0}' -f $linkNumber
            LinkNumber        = $linkNumber
        }
        return $pscriboLink
    }
}
