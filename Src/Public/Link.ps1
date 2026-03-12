function Link
{
<#
    .SYNOPSIS
        Paragraphs can contain hyperlinks (links) inline. A link renders as
        a clickable hyperlink in Html and Word output, and as text (uri) in
        text-based output.

    .NOTES
        The "Link" block command can only be used within a Paragraph -ScriptBlock { }
#>
    [CmdletBinding()]
    param
    (
        ## Hyperlink display text
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [AllowEmptyString()]
        [System.String] $Text,

        ## Hyperlink URI/URL target
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $Uri,

        ## Open link in a new window/tab (Html output only)
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $NewWindow,

        ## No space applied between this link and the next text block
        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Management.Automation.SwitchParameter] $NoSpace
    )
    begin
    {
        $psCallStack = Get-PSCallStack | Where-Object { $_.FunctionName -ne '<ScriptBlock>' }
        if ($psCallStack[1].FunctionName -ne 'Paragraph<Process>')
        {
            throw $localized.LinkRunRootError
        }
    }
    process
    {
        $linkDisplayName = $Text
        if ($Text.Length -gt 40)
        {
            $linkDisplayName = '{0}[..]' -f $Text.Substring(0,36)
        }
        Write-PScriboMessage -Message ($localized.ProcessingLink -f $linkDisplayName)
        return (New-PScriboLink @PSBoundParameters)
    }
}
