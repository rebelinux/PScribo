function ConvertTo-Image {
    <#
    .SYNOPSIS
        Creates an image from a byte[]
#>
    [CmdletBinding()]
    [OutputType([System.Drawing.Image], [SixLabors.ImageSharp.Image])]
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
                [SixLabors.ImageSharp.Image] $image = [SixLabors.ImageSharp.Image]::Load($memoryStream)
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
