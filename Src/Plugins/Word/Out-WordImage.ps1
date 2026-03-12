function Out-WordImage
{
<#
    .SYNOPSIS
        Output Image to Word.
#>
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.PSObject] $Image,

        [Parameter(Mandatory)]
        [System.Xml.XmlDocument] $XmlDocument
    )
    process
    {
        $xmlnsMain = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
        $xmlnswpDrawingWordProcessing = 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'
        $xmlnsDrawingMain = 'http://schemas.openxmlformats.org/drawingml/2006/main'
        $xmlnsDrawingPicture = 'http://schemas.openxmlformats.org/drawingml/2006/picture'
        $xmlnsRelationships = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'

        $p = $XmlDocument.CreateElement('w', 'p', $xmlnsMain)
        $pPr = $p.AppendChild($XmlDocument.CreateElement('w', 'pPr', $xmlnsMain))
        $spacing = $pPr.AppendChild($XmlDocument.CreateElement('w', 'spacing', $xmlnsMain))
        [ref] $null = $spacing.SetAttribute('before', $xmlnsMain, 0)
        [ref] $null = $spacing.SetAttribute('after', $xmlnsMain, 0)

        $jc = $pPr.AppendChild($XmlDocument.CreateElement('w', 'jc', $xmlnsMain))
        [ref] $null = $jc.SetAttribute('val', $xmlnsMain, $Image.Align.ToLower())

        $r = $p.AppendChild($XmlDocument.CreateElement('w', 'r', $xmlnsMain))
        [ref] $null = $r.AppendChild($XmlDocument.CreateElement('w', 'rPr', $xmlnsMain))
        $drawing = $r.AppendChild($XmlDocument.CreateElement('w', 'drawing', $xmlnsMain))

        $wrap = if ($Image.PSObject.Properties['Wrap']) { $Image.Wrap } else { 'Inline' }

        if ($wrap -eq 'Inline')
        {
            $container = $drawing.AppendChild($XmlDocument.CreateElement('wp', 'inline', $xmlnswpDrawingWordProcessing))
            [ref] $null = $container.SetAttribute('distT', '0')
            [ref] $null = $container.SetAttribute('distB', '0')
            [ref] $null = $container.SetAttribute('distL', '0')
            [ref] $null = $container.SetAttribute('distR', '0')
        }
        else
        {
            $container = $drawing.AppendChild($XmlDocument.CreateElement('wp', 'anchor', $xmlnswpDrawingWordProcessing))
            [ref] $null = $container.SetAttribute('distT', '0')
            [ref] $null = $container.SetAttribute('distB', '0')
            [ref] $null = $container.SetAttribute('distL', '114300')
            [ref] $null = $container.SetAttribute('distR', '114300')
            [ref] $null = $container.SetAttribute('simplePos', '0')
            ## 251658240 = 0x0F000000, standard default z-order for floating images in Word
            [ref] $null = $container.SetAttribute('relativeHeight', '251658240')
            [ref] $null = $container.SetAttribute('behindDoc', '0')
            [ref] $null = $container.SetAttribute('locked', '0')
            [ref] $null = $container.SetAttribute('layoutInCell', '1')
            [ref] $null = $container.SetAttribute('allowOverlap', '1')

            $simplePos = $container.AppendChild($XmlDocument.CreateElement('wp', 'simplePos', $xmlnswpDrawingWordProcessing))
            [ref] $null = $simplePos.SetAttribute('x', '0')
            [ref] $null = $simplePos.SetAttribute('y', '0')

            $positionH = $container.AppendChild($XmlDocument.CreateElement('wp', 'positionH', $xmlnswpDrawingWordProcessing))
            [ref] $null = $positionH.SetAttribute('relativeFrom', 'column')
            $posOffsetH = $positionH.AppendChild($XmlDocument.CreateElement('wp', 'posOffset', $xmlnswpDrawingWordProcessing))
            [ref] $null = $posOffsetH.AppendChild($XmlDocument.CreateTextNode('0'))

            $positionV = $container.AppendChild($XmlDocument.CreateElement('wp', 'positionV', $xmlnswpDrawingWordProcessing))
            [ref] $null = $positionV.SetAttribute('relativeFrom', 'paragraph')
            $posOffsetV = $positionV.AppendChild($XmlDocument.CreateElement('wp', 'posOffset', $xmlnswpDrawingWordProcessing))
            [ref] $null = $posOffsetV.AppendChild($XmlDocument.CreateTextNode('0'))
        }

        $extent = $container.AppendChild($XmlDocument.CreateElement('wp', 'extent', $xmlnswpDrawingWordProcessing))
        [ref] $null = $extent.SetAttribute('cx', $Image.WidthEm)
        [ref] $null = $extent.SetAttribute('cy', $Image.HeightEm)

        $effectExtent = $container.AppendChild($XmlDocument.CreateElement('wp', 'effectExtent', $xmlnswpDrawingWordProcessing))
        [ref] $null = $effectExtent.SetAttribute('l', '0')
        [ref] $null = $effectExtent.SetAttribute('t', '0')
        [ref] $null = $effectExtent.SetAttribute('r', '0')
        [ref] $null = $effectExtent.SetAttribute('b', '0')

        ## Add wrap element for anchor-based images
        switch ($wrap)
        {
            'Square'
            {
                $wrapElement = $container.AppendChild($XmlDocument.CreateElement('wp', 'wrapSquare', $xmlnswpDrawingWordProcessing))
                [ref] $null = $wrapElement.SetAttribute('wrapText', 'bothSides')
            }
            { $_ -in 'Tight', 'Through' }
            {
                $wrapTagName = if ($wrap -eq 'Tight') { 'wrapTight' } else { 'wrapThrough' }
                $wrapElement = $container.AppendChild($XmlDocument.CreateElement('wp', $wrapTagName, $xmlnswpDrawingWordProcessing))
                [ref] $null = $wrapElement.SetAttribute('wrapText', 'bothSides')
                ## Rectangle polygon in Word's EMU-based drawing coordinates (21600 = full extent)
                $wrapPolygon = $wrapElement.AppendChild($XmlDocument.CreateElement('wp', 'wrapPolygon', $xmlnswpDrawingWordProcessing))
                [ref] $null = $wrapPolygon.SetAttribute('edited', '0')
                $start = $wrapPolygon.AppendChild($XmlDocument.CreateElement('wp', 'start', $xmlnswpDrawingWordProcessing))
                [ref] $null = $start.SetAttribute('x', '0')
                [ref] $null = $start.SetAttribute('y', '0')
                foreach ($point in @(@(0,21600),@(21600,21600),@(21600,0),@(0,0)))
                {
                    $lineTo = $wrapPolygon.AppendChild($XmlDocument.CreateElement('wp', 'lineTo', $xmlnswpDrawingWordProcessing))
                    [ref] $null = $lineTo.SetAttribute('x', $point[0])
                    [ref] $null = $lineTo.SetAttribute('y', $point[1])
                }
            }
            'TopBottom'
            {
                [ref] $null = $container.AppendChild($XmlDocument.CreateElement('wp', 'wrapTopAndBottom', $xmlnswpDrawingWordProcessing))
            }
            'None'
            {
                [ref] $null = $container.AppendChild($XmlDocument.CreateElement('wp', 'wrapNone', $xmlnswpDrawingWordProcessing))
            }
        }

        $docPr = $container.AppendChild($XmlDocument.CreateElement('wp', 'docPr', $xmlnswpDrawingWordProcessing))
        [ref] $null = $docPr.SetAttribute('id', $Image.ImageNumber)
        [ref] $null = $docPr.SetAttribute('name', $Image.Name)
        [ref] $null = $docPr.SetAttribute('descr', $Image.Name)

        $cNvGraphicFramePr = $container.AppendChild($XmlDocument.CreateElement('wp', 'cNvGraphicFramePr', $xmlnswpDrawingWordProcessing))
        $graphicFrameLocks = $cNvGraphicFramePr.AppendChild($XmlDocument.CreateElement('a', 'graphicFrameLocks', $xmlnsDrawingMain))
        [ref] $null = $graphicFrameLocks.SetAttribute('noChangeAspect', '1')

        $graphic = $container.AppendChild($XmlDocument.CreateElement('a', 'graphic', $xmlnsDrawingMain))
        $graphicData = $graphic.AppendChild($XmlDocument.CreateElement('a', 'graphicData', $xmlnsDrawingMain))
        [ref] $null = $graphicData.SetAttribute('uri', 'http://schemas.openxmlformats.org/drawingml/2006/picture')

        $pic = $graphicData.AppendChild($XmlDocument.CreateElement('pic', 'pic', $xmlnsDrawingPicture))
        $nvPicPr = $pic.AppendChild($XmlDocument.CreateElement('pic', 'nvPicPr', $xmlnsDrawingPicture))
        $cNvPr = $nvPicPr.AppendChild($XmlDocument.CreateElement('pic', 'cNvPr', $xmlnsDrawingPicture))
        [ref] $null = $cNvPr.SetAttribute('id', $Image.ImageNumber)
        [ref] $null = $cNvPr.SetAttribute('name', $Image.Name)
        [ref] $null = $cNvPr.SetAttribute('descr', $Image.Name)
        $cNvPicPr = $nvPicPr.AppendChild($XmlDocument.CreateElement('pic', 'cNvPicPr', $xmlnsDrawingPicture))
        $picLocks = $cNvPicPr.AppendChild($XmlDocument.CreateElement('a', 'picLocks', $xmlnsDrawingMain))
        [ref] $null = $picLocks.SetAttribute('noChangeAspect', '1')
        [ref] $null = $picLocks.SetAttribute('noChangeArrowheads', '1')

        $blipFill = $pic.AppendChild($XmlDocument.CreateElement('pic', 'blipFill', $xmlnsDrawingPicture))
        $blip = $blipFill.AppendChild($XmlDocument.CreateElement('a', 'blip', $xmlnsDrawingMain))
        [ref] $null = $blip.SetAttribute('embed', $xmlnsRelationships, $Image.Name)
        [ref] $null = $blip.SetAttribute('cstate', 'print')
        $extlst = $blip.AppendChild($XmlDocument.CreateElement('a', 'extlst', $xmlnsDrawingMain))
        $ext = $extlst.AppendChild($XmlDocument.CreateElement('a', 'ext', $xmlnsDrawingMain))
        [ref] $null = $ext.SetAttribute('uri', '')
        [ref] $null = $blipFill.AppendChild($XmlDocument.CreateElement('a', 'srcRect', $xmlnsDrawingMain))
        $stretch = $blipFill.AppendChild($XmlDocument.CreateElement('a', 'stretch', $xmlnsDrawingMain))
        [ref] $null = $stretch.AppendChild($XmlDocument.CreateElement('a', 'fillRect', $xmlnsDrawingMain))

        $spPr = $pic.AppendChild($XmlDocument.CreateElement('pic', 'spPr', $xmlnsDrawingPicture))
        [ref] $null = $spPr.SetAttribute('bwMode', 'auto')
        $xfrm = $spPr.AppendChild($XmlDocument.CreateElement('a', 'xfrm', $xmlnsDrawingMain))
        $off = $xfrm.AppendChild($XmlDocument.CreateElement('a', 'off', $xmlnsDrawingMain))
        [ref] $null = $off.SetAttribute('x', '0')
        [ref] $null = $off.SetAttribute('y', '0')
        $ext = $xfrm.AppendChild($XmlDocument.CreateElement('a', 'ext', $xmlnsDrawingMain))
        [ref] $null = $ext.SetAttribute('cx', $Image.WidthEm)
        [ref] $null = $ext.SetAttribute('cy', $Image.HeightEm)

        $prstGeom = $spPr.AppendChild($XmlDocument.CreateElement('a', 'prstGeom', $xmlnsDrawingMain))
        [ref] $null = $prstGeom.SetAttribute('prst', 'rect')
        [ref] $null = $prstGeom.AppendChild($XmlDocument.CreateElement('a', 'avLst', $xmlnsDrawingMain))

        [ref] $null = $spPr.AppendChild($XmlDocument.CreateElement('a', 'noFill', $xmlnsDrawingMain))

        $ln = $spPr.AppendChild($XmlDocument.CreateElement('a', 'ln', $xmlnsDrawingMain))
        [ref] $null = $ln.AppendChild($XmlDocument.CreateElement('a', 'noFill', $xmlnsDrawingMain))

        return $p
    }
}
