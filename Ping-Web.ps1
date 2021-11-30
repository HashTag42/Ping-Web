<#
.Synopsis
   Pings the specified URI.
.DESCRIPTION
   Verifies connectivity to a web page or web service by repeatedly sending HTTP or HTTPS requests.
.EXAMPLE
   .\Ping-Web.ps1 -URI https://www.bungie.net
.EXAMPLE
   .\Ping-Web.ps1 -URI https://www.bungie.net -CsvFile D:\ping-data.csv
.EXAMPLE
   .\Ping-Web.ps1 -URI https://www.bungie.net -Count 4
.EXAMPLE
   .\Ping-Web.ps1 -URI https://www.bungie.net -TimeoutSec 10
.EXAMPLE
   .\Ping-Web.ps1 -URI https://www.bungie.net -SleepSec 3
.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest
.NOTES
   Author:  cgarcia
   Version:  1.0
   Date Modified:  2021-10-11
#>

[CmdletBinding()]
Param(
    # Specifies the Uniform Resource Identifier (URI) of the internet resource to which the web request is sent.
    # Enter a URI. This parameter supports HTTP or HTTPS only.
    [Parameter(Mandatory = $True)]
    [String] $URI = 'https://www.bungie.net',

    # Specifies the number of requests to be sent.
    # A value of 0 specifies an unlimited number of requests.
    [ValidateRange(0, [UInt]::MaxValue)]
    [UInt] $Count = 0,

    # Specifies how long the request can be pending before it times out. Enter a value in seconds.
    # The default value, 0, specifies an indefinite time-out.
    [ValidateRange(0, [UInt]::MaxValue)]
    [UInt] $TimeoutSec = 0,

    # Specifies how long to wait in between requests. Enter a value in seconds.
    [ValidateRange(0, [UInt]::MaxValue)]
    [UInt] $SleepSec = 1,

    # Specifies a CSV file to output data to
    [String] $CsvFile
)

[Bool] $InfiniteMode = $False
If( $Count -eq 0 ) {
    $InfiniteMode = $True
}

[UInt64] $count = 1
While( $InfiniteMode -or ( $count -le $Count ) ) {

    [System.DateTime] $startTime = Get-Date

    $results = [PSCustomObject]@{
        Count                   = $count
        URI                     = $URI
        StartTime               = $startTime.ToString('O')
        StatusCode              = $Null
        StatusDescription       = $Null
        ElapsedTimeInMS         = $Null
        RawResponseLength       = $Null
        XBungieNextMid2Header   = $Null
    }

    Try {
        [Microsoft.PowerShell.Commands.WebResponseObject] `
        $response = Invoke-WebRequest -Uri $URI -TimeoutSec $TimeoutSec -DisableKeepAlive

        $results.StatusCode         = $response.StatusCode
        $results.StatusDescription  = $response.StatusDescription
        $results.RawResponseLength  = $response.RawContentLength

        # Includes a response header only available from Bnet sites, if available
        If( $response.Headers.ContainsKey('X-BungieNext-MID2') ) {
            $results.XBungieNextMid2Header = $response.Headers['X-BungieNext-MID2'][0]
        }
    }
    Catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $results.StatusCode         = [int] $PSitem.Exception.Response.StatusCode
        $results.StatusDescription  = $PSitem.Exception.Response.StatusCode
    }
    Catch [System.Net.Sockets.SocketException] {
        $results.StatusCode         = $PSItem.Exception.StatusCode
        $results.StatusDescription  = $PSItem.Exception.Message
    }
    Catch {
        $results.StatusCode         = $response.StatusCode
        $results.StatusDescription  = $PSItem.Exception.Message
    }
    Finally {
        [TimeSpan] $elapsedTime = (New-TimeSpan -Start $startTime -End (Get-Date))
        $results.ElapsedTimeInMS    = $elapsedTime.TotalMilliseconds
    }

    Write-Host $results | Format-Table -AutoSize
    if( $CsvFile ) {
        Write-Output $results | Export-Csv -Path $CsvFile -Append -NoTypeInformation -Force
    }

    Start-Sleep -Seconds $SleepSec

    $count++
}
