<#
.Synopsis
    This script calculates statstics from a CSV file created by the Ping-Web.ps1 CmdLet.
#>
[CmdletBinding()]
param (
    # [Parameter(Mandatory= $true)]
    [ValidateScript( {Test-Path -Path $_} )]
    [String]
    $CsvFile = '.\Ping-Web_data.csv'
)

function Measure-PingStats {

    begin {

    }

    process {
        $csv= Import-Csv -Path $CsvFile
        $csv | Get-Member
        $csv | Measure-Object -AllStats -Property ElapsedTimeInMS
    }

    end {

    }
}

Measure-PingStats