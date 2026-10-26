function ConvertTo-Image {
    <#
    .SYNOPSIS
        Creates an image from a byte[]
#>
    [CmdletBinding()]
    [OutputType([System.Drawing.Image], [SkiaSharp.SKImage])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Byte[]] $Bytes
    )
    process {
        try {
            $Plataform = if ($PSVersionTable.PSEdition -eq 'Core') {
                if ($IsLinux -or $IsMacOS) {
                    'Unix'
                }
                else {
                    'Windows'
                }
            }
            else {
                'Windows'
            }
            if ($Plataform -eq 'Unix') {
                $memoryStream = [System.IO.MemoryStream]::new($Bytes)
                [SkiaSharp.SKImage] $image = [SkiaSharp.SKImage]::FromEncodedData($memoryStream)
                Write-Output -InputObject $image
            }
            else {
                [System.IO.MemoryStream] $memoryStream = New-Object -TypeName 'System.IO.MemoryStream' -ArgumentList @(, $Bytes)
                [System.Drawing.Image] $image = [System.Drawing.Image]::FromStream($memoryStream)
                Write-Output -InputObject $image
            }
        }
        catch {
            $_
        }
        finally {
            if ($null -ne $memoryStream) {
                $memoryStream.Close()
            }
        }
    }
}
