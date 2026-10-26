function Get-ImageMimeType {
    <#
    .SYNOPSIS
        Returns an image's Mime type
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Object] $Image
    )
    process {
        # Check if running on Unix and ImageSharp is available
        $Platform = if ($PSVersionTable.PSEdition -eq 'Core') {
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
        if ($Platform -eq 'Unix') {
            # Use SkiaSharp's encoded image format on Unix systems
            $codec = [SkiaSharp.SKCodec]::Create($Image.EncodedData)
            $format = $codec.EncodedFormat
            if ($format) {
                switch ($format.ToString().ToLowerInvariant()) {
                    'jpeg' { return 'image/jpeg' }
                    'png' { return 'image/png' }
                    'bmp' { return 'image/bmp' }
                    'gif' { return 'image/gif' }
                    'webp' { return 'image/webp' }
                    'ico' { return 'image/x-icon' }
                    'wbmp' { return 'image/vnd.wap.wbmp' }
                    'heif' { return 'image/heif' }
                    'avif' { return 'image/avif' }
                    default { return 'image/unknown' }
                }
            }
        }
        else {
            # Use System.Drawing on Windows
            if ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Jpeg)) {
                return 'image/jpeg'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Png)) {
                return 'image/png'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Bmp)) {
                return 'image/bmp'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Emf)) {
                return 'image/emf'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Gif)) {
                return 'image/gif'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Icon)) {
                return 'image/icon'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Tiff)) {
                return 'image/tiff'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Wmf)) {
                return 'image/wmf'
            }
            elseif ($Image.RawFormat.Equals([System.Drawing.Imaging.ImageFormat]::Exif)) {
                return 'image/exif'
            }
        }
        return 'image/unknown'
    }
}