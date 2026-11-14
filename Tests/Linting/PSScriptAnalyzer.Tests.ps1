#requires -Version 4
#requires -Modules PSScriptAnalyzer

$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$sourceFiles = @(Get-ChildItem -Path "$repoRoot\Src\*.ps*1" -Recurse -File)
$testCases = @(
    foreach ($file in $sourceFiles) {
        @{
            Path = $file.FullName
            RelativePath = $file.FullName.Replace($repoRoot, '')
        }
    }
)

Describe 'Linting\PSScriptAnalyzer' {
    It "File '<RelativePath>' passes PSScriptAnalyzer rules" -ForEach $testCases {
        param ($Path)

        $result = Invoke-ScriptAnalyzer -Path $Path -Severity Warning | Select-Object -ExpandProperty Message
        $result | Should -BeNullOrEmpty
    }
}
