function Get-WordNumberingDocument
{
<#
    .SYNOPSIS
        Outputs Office Open XML numbering document
#>
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param
    (
        ## PScribo document styles
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList] $Lists,

        [Parameter()]
        [System.Management.Automation.SwitchParameter] $EnableWordSectionNumbering
    )
    process
    {
        ## Create the numbering.xml document
        $xmlns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
        $xmlDocument = New-Object -TypeName 'System.Xml.XmlDocument'
        [ref] $null = $xmlDocument.AppendChild($XmlDocument.CreateXmlDeclaration('1.0', 'utf-8', 'yes'))
        $numbering = $xmlDocument.AppendChild($xmlDocument.CreateElement('w', 'numbering', $xmlns))
        [ref] $null = $xmlDocument.DocumentElement.SetAttribute('xmlns:mc', 'http://schemas.openxmlformats.org/markup-compatibility/2006')
        [ref] $null = $xmlDocument.DocumentElement.SetAttribute('xmlns:w14', 'http://schemas.microsoft.com/office/word/2010/wordml')

        foreach ($list in $Lists.GetEnumerator())
        {
            $abstractNum = Get-WordNumberStyle -List $list -XmlDocument $xmlDocument
            [ref] $null = $numbering.AppendChild($abstractNum)
        }

        if ($EnableWordSectionNumbering)
        {
            $abstractNumIdValue = $Lists.Count
            $abstractNum = $numbering.AppendChild($xmlDocument.CreateElement('w', 'abstractNum', $xmlns))
            [ref] $null = $abstractNum.SetAttribute('abstractNumId', $xmlns, $abstractNumIdValue)
            $multiLevelType = $abstractNum.AppendChild($xmlDocument.CreateElement('w', 'multiLevelType', $xmlns))
            [ref] $null = $multiLevelType.SetAttribute('val', $xmlns, 'multilevel')

            ## Word supports up to nine numbering levels.
            foreach ($level in 0..8)
            {
                $lvl = $abstractNum.AppendChild($xmlDocument.CreateElement('w', 'lvl', $xmlns))
                [ref] $null = $lvl.SetAttribute('ilvl', $xmlns, $level)
                $start = $lvl.AppendChild($xmlDocument.CreateElement('w', 'start', $xmlns))
                [ref] $null = $start.SetAttribute('val', $xmlns, 1)
                $numFmt = $lvl.AppendChild($xmlDocument.CreateElement('w', 'numFmt', $xmlns))
                [ref] $null = $numFmt.SetAttribute('val', $xmlns, 'decimal')
                $lvlText = $lvl.AppendChild($xmlDocument.CreateElement('w', 'lvlText', $xmlns))
                $numberParts = 0..$level | ForEach-Object { '%{0}' -f ($_ + 1) }
                [ref] $null = $lvlText.SetAttribute('val', $xmlns, ('{0}.' -f ($numberParts -join '.')))
                $lvlJc = $lvl.AppendChild($xmlDocument.CreateElement('w', 'lvlJc', $xmlns))
                [ref] $null = $lvlJc.SetAttribute('val', $xmlns, 'left')
            }
        }

        foreach ($list in $Lists.GetEnumerator())
        {
            $num = $numbering.AppendChild($xmlDocument.CreateElement('w', 'num', $xmlns))
            [ref] $null = $num.SetAttribute('numId', $xmlns, $list.Number)
            $abstractNumId = $num.AppendChild($xmlDocument.CreateElement('w', 'abstractNumId', $xmlns))
            [ref] $null = $abstractNumId.SetAttribute('val', $xmlns, $list.Number -1)
        }

        if ($EnableWordSectionNumbering)
        {
            $num = $numbering.AppendChild($xmlDocument.CreateElement('w', 'num', $xmlns))
            [ref] $null = $num.SetAttribute('numId', $xmlns, $abstractNumIdValue + 1)
            $abstractNumId = $num.AppendChild($xmlDocument.CreateElement('w', 'abstractNumId', $xmlns))
            [ref] $null = $abstractNumId.SetAttribute('val', $xmlns, $abstractNumIdValue)
        }

        return $xmlDocument
    }
}
