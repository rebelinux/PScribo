Set-StrictMode -Version Latest

## Import localisation strings based on UICulture
$importLocalizedDataParams = @{
    BindingVariable = 'localized'
    BaseDirectory   = $PSScriptRoot
    FileName        = 'PScribo.Resources.psd1'
}
Import-LocalizedData @importLocalizedDataParams -ErrorAction SilentlyContinue

#Fallback to en-US culture strings
if (-not (Test-Path -Path 'Variable:\localized')) {
    $importLocalizedDataParams['UICulture'] = 'en-US'
    Import-LocalizedData @importLocalizedDataParams -ErrorAction Stop
}

# Get assemblies files and import them
$assemblyName = @(Get-ChildItem -Path ("$PSScriptRoot{0}Src{0}Bin{0}Assemblies{0}*.dll" -f [System.IO.Path]::DirectorySeparatorChar) -ErrorAction SilentlyContinue)

$loadedassemblies = [System.AppDomain]::CurrentDomain.GetAssemblies().ManifestModule.Name

foreach ($Assembly in $assemblyName) {
    if ($Assembly.Name -notin $loadedassemblies) {
        try {
            Write-Verbose -Message "Loading assembly '$($Assembly.Name)'."
            Add-Type -Path $Assembly.FullName -Verbose
        }
        catch {
            Write-Error -Message "Failed to add assembly $($Assembly.FullName): $_"
        }
    }
}

## Dot source all the nested .ps1 files in the \Functions and \Plugin folders, excluding tests
$pscriboRoot = Split-Path -Parent $PSCommandPath
Get-ChildItem -Path "$pscriboRoot\Src\" -Include '*.ps1' -Recurse |
ForEach-Object {
    Write-Debug ($localized.ImportingFile -f $_.FullName)
    ## https://becomelotr.wordpress.com/2017/02/13/expensive-dot-sourcing/
    . ([System.Management.Automation.ScriptBlock]::Create(
            [System.IO.File]::ReadAllText($_.FullName)
        ))
}

Add-Type -AssemblyName 'System.Drawing'
#Export-ModuleMember -Function $exportedFunctions -Alias $exportedAliases -Verbose:$false
