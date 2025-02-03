<#
.Synopsis
   Start the Ping-Web process against a list of URLs listed on a text file.
#>

[CmdletBinding()]
Param(
    [String] $Script = '.\Ping-Web.ps1',

    [String] $SitesFile = '.\sites.txt',

    [String] $OutputPath = $ENV:TEMP
)

[String] $workingDirectory = Get-Location
Write-Debug ("workingDirectory = $workingDirectory")

[String] $timeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

if (-Not (Test-Path $SitesFile)) {
    Write-Error "Sites file '$SitesFile' could not be found."
    exit
}

try {
    [String[]] $sites = Get-Content $SitesFile
}
catch {
    exit
}

ForEach($site in $sites) {
    if ($site[0] -ne '#') {
        [String] $encodedUrl = [System.Web.HttpUtility]::UrlEncode($site)

        [String] $outputFile = Join-Path $OutputPath ($timeStamp + '_' + $encodedUrl + '.csv')
        Write-Output ("Output file: " + $outputFile)

        [Hashtable] $processOptions = @{
            FilePath = 'pwsh.exe'
            ArgumentList = @(
                '-WorkingDirectory ' + $workingDirectory
                '-NoExit'
                '-WindowStyle Normal'
                '-Command ' + $Script
                # Script parameters:
                    '-URI ' + $site
                    '-SleepSec 0'
                    '-CsvFile ' + $outputFile
            )
        }

        Start-Process @processOptions
    }
}