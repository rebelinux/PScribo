$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$excludedPaths = @(
    '.git*',
    '.vscode',
    'DSCResources',
    'Release',
    '*.png',
    '*.jpg',
    '*.docx',
    '*.enc',
    '*.dll',
    '*.so',
    '*.dylib',
    'appveyor-tools',
    'TestResults.xml',
    'Tests',
    'Docs',
    'PScriboExample.txt',
    'Lib'
)

function Get-StyleFiles {
    param (
        [Parameter(Mandatory)]
        [string] $Path,

        [string[]] $Exclude
    )

    foreach ($item in Get-ChildItem -Path $Path -Exclude $Exclude) {
        if ($item -is [System.IO.FileInfo]) {
            $item
        }
        elseif ($item -is [System.IO.DirectoryInfo]) {
            Get-StyleFiles -Path $item.FullName -Exclude $Exclude
        }
    }
}

$styleTestCases = @(
    foreach ($file in Get-StyleFiles -Path $repoRoot -Exclude $excludedPaths) {
        @{
            Path = $file.FullName
            RelativePath = $file.FullName.Replace($repoRoot, '')
        }
    }
)

Describe 'Linting\Style' -Tags 'Style' {
    It "File '<RelativePath>' contains no trailing whitespace" -ForEach $styleTestCases {
        param ($Path)

        $lines = [System.IO.File]::ReadAllLines($Path)
        $badLines = @(
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '\s+$') {
                    'File: {0}, Line: {1}' -f $Path, ($i + 1)
                }
            }
        )

        @($badLines).Count | Should -Be 0
    }

    It "File '<RelativePath>' ends with a newline" -ForEach $styleTestCases {
        param ($Path)

        $string = [System.IO.File]::ReadAllText($Path)
        ($string.Length -gt 0 -and $string[-1] -ne "`n") | Should -Be $false
    }
}
