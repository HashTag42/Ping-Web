<#
.Synopsis
   Pings the specified URL.
.DESCRIPTION
   Verifies connectivity to a web page or web service by repeatedly sending HTTP or HTTPS requests.
.EXAMPLE
   .\Ping-Web.ps1 -URL cesar-garcia.com
.EXAMPLE
   .\Ping-Web.ps1 -URL cesar-garcia.com -CsvFile .\ping-web_data.csv
.EXAMPLE
   .\Ping-Web.ps1 -URL cesar-garcia.com -Count 4
.EXAMPLE
   .\Ping-Web.ps1 -URL cesar-garcia.com -TimeoutSec 10
.EXAMPLE
   .\Ping-Web.ps1 -URL cesar-garcia.com -SleepSec 3
.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest
.NOTES
   Author:  Cesar Garcia
   Version:  1.2
   Date Modified:  2025-09-02
#>

[CmdletBinding()]
Param(
    # Specifies the Uniform Resource Identifier (URL) of the internet resource to which the web request is sent.
    # Enter a URL. This parameter supports HTTP or HTTPS only.
    [String] $URL = "cesar-garcia.com",

    # Specifies the number of requests to be sent.
    # A value of 0 specifies an unlimited number of requests.
    [ValidateRange(0, [UInt]::MaxValue)]
    [UInt] $Count = 4,

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

Write-Host "Sending web requests to: $URL"

If ($CsvFile -eq "") {
    $TmpFile = [System.IO.Path]::GetTempFileName()
    $CsvFile = [System.IO.Path]::ChangeExtension($TmpFile, ".csv")
}

If( $Count -eq 0 ) {
    $InfiniteMode = $True
}
Else {
    $InfiniteMode = $False
}

[UInt64] $n = 1
While( $InfiniteMode -or ( $n -le $Count ) ) {

    [System.DateTime] $startTime = Get-Date

    $results = [PSCustomObject]@{
        Count                   = $n
        URL                     = $URL
        StartTime               = $startTime.ToString('O')
        StatusCode              = $Null
        StatusDescription       = $Null
        ElapsedTimeInMS         = $Null
        RawResponseLength       = $Null
    }

    Try {
        [Microsoft.PowerShell.Commands.WebResponseObject] `
        $response = Invoke-WebRequest -URI $URL -TimeoutSec $TimeoutSec -DisableKeepAlive
        $results.StatusCode         = $response.StatusCode
        $results.StatusDescription  = $response.StatusDescription
        $results.RawResponseLength  = $response.RawContentLength
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

    $n++
}

Write-Host "Detailed results saved at $CsvFile"
Write-Host "Statistics for response time in milli-seconds for: $URL"
Import-Csv -Path $CsvFile | Measure-Object -Property ElapsedTimeInMS -AllStats
