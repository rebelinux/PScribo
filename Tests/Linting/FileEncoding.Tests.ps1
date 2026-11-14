$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$excludedPaths = @(
    '.git*',
    '.vscode',
    'Release',
    '*.png',
    '*.jpg',
    '*.docx',
    '*.enc',
    '*.dll',
    'appveyor-tools',
    'TestResults.xml',
    'Tests',
    'Docs',
    'PScriboExample.*',
    'Lib',
    'Get-WordNumberStyle.ps1'
)

function Get-TestFiles {
    param (
        [Parameter(Mandatory)]
        [string] $Path,

        [string[]] $Exclude
    )

    foreach ($item in Get-ChildItem -Path $Path -Exclude $Exclude) {
        if ($item -is [System.IO.FileInfo]) {
            if ($item.Name -ne 'Resolve-ProgramFilesFolder.ps1') {
                $item
            }
        }
        elseif ($item -is [System.IO.DirectoryInfo]) {
            Get-TestFiles -Path $item.FullName -Exclude $Exclude
        }
    }
}

$fileEncodingTestCases = @(
    foreach ($file in Get-TestFiles -Path $repoRoot -Exclude $excludedPaths) {
        @{
            Path = $file.FullName
            RelativePath = $file.FullName.Replace($repoRoot, '')
        }
    }
)

Describe 'Linting\FileEncoding' {
    BeforeAll {
        function Get-FileEncoding {
            param (
                [Parameter(Mandatory)]
                [string] $Path
            )

            $bytes = [System.IO.File]::ReadAllBytes($Path)
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
                return [System.Text.Encoding]::UTF32
            }
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                return [System.Text.Encoding]::UTF32
            }
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                return [System.Text.Encoding]::UTF8
            }
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                return [System.Text.Encoding]::Unicode
            }
            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
                return [System.Text.Encoding]::BigEndianUnicode
            }

            [System.Text.Encoding]::ASCII
        }
    }

    It "File '<RelativePath>' uses UTF-8 (no BOM) encoding" -ForEach $fileEncodingTestCases {
        param ($Path)

        (Get-FileEncoding -Path $Path).HeaderName | Should -Be 'us-ascii'
    }
}
