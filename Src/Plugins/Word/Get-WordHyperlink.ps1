function Get-WordHyperlink
{
<#
    .SYNOPSIS
        Outputs a Word hyperlink (w:hyperlink) element wrapping a text run.

    .NOTES
        External links use a document relationship (r:id) which cannot be created in
        header/footer parts, so those are rendered as plain runs.
#>
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSObject] $Segment,

        [Parameter(Mandatory)]
        [System.Xml.XmlElement] $RunProperties,

        [Parameter(Mandatory)]
        [System.Xml.XmlDocument] $XmlDocument
    )
    process
    {
        $xmlns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
        $xmlnsrelationships = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
        $displayText = Get-PScriboLinkDisplayText -Segment $Segment

        $rPr = $RunProperties.CloneNode($true)
        if ($null -eq $rPr.SelectSingleNode('*[local-name()="rStyle"]'))
        {
            $rStyle = $XmlDocument.CreateElement('w', 'rStyle', $xmlns)
            [ref] $null = $rStyle.SetAttribute('val', $xmlns, 'Hyperlink')
            [ref] $null = $rPr.PrependChild($rStyle)
        }

        $hyperlink = $XmlDocument.CreateElement('w', 'hyperlink', $xmlns)
        if ($Segment.IsExternal)
        {
            $relationshipId = Get-WordHyperlinkRelationshipId -Uri $Segment.Target
            $idAttribute = $XmlDocument.CreateAttribute('r', 'id', $xmlnsrelationships)
            $idAttribute.Value = $relationshipId
            [ref] $null = $hyperlink.SetAttributeNode($idAttribute)
        }
        else
        {
            [ref] $null = $hyperlink.SetAttribute('anchor', $xmlns, $Segment.AnchorName)
        }
        [ref] $null = $hyperlink.SetAttribute('history', $xmlns, '1')

        $r = $hyperlink.AppendChild($XmlDocument.CreateElement('w', 'r', $xmlns))
        [ref] $null = $r.AppendChild($rPr)
        $t = $r.AppendChild($XmlDocument.CreateElement('w', 't', $xmlns))
        if ($displayText -ne $displayText.Trim())
        {
            [ref] $null = $t.SetAttribute('space', 'http://www.w3.org/XML/1998/namespace', 'preserve')
        }
        [ref] $null = $t.AppendChild($XmlDocument.CreateTextNode($displayText))
        return $hyperlink
    }
}
