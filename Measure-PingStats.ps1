<#
.Synopsis
    This script calculates statstics from a CSV file created by the Ping-Web.ps1 CmdLet.
#>
[CmdletBinding()]
param (
    # [Parameter(Mandatory= $true)]
    [ValidateScript( {Test-Path -Path $_} )]
    [String]
    $CsvFile = "C:\Users\cgarcia\AppData\Local\Temp\2021-11-11_15-45-26_stage.bungie.net.csv"
)

function Measure-PingStats {

    begin {

    }

    process {
        $csv= Import-Csv -Path $CsvFile
        $csv | Get-Member
        $csv | Measure-Object  -AllStats -Property StatusCode
        $csv | Measure-Object  -AllStats -Property Milliseconds
    }

    end {

    }
}

Measure-PingStats