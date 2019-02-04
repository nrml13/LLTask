<#
.SYNOPSIS
  Runner.ps1 => tests the LL classes
.DESCRIPTION
  This script contains only one example function.
  It needs to executed in a powershell terminal without storing the result into a variable.
  ScanNetworkTwoWay() => This method compare the time taking during a scan of the host network.
  The first item is a measure-command of the sequential way, the second is a measure-command of the parallel way and the third is the result of the parallel way (just to show what it's look like).
  For both methods the result is an hashtable @{Ip, PingResult})
.INPUTS
  None
.OUTPUTS
  Display texts and object in the terminal
.NOTES
  Version:        0.4
  Author:         Marlon Gatto
  Creation Date:  04/02/2019
  Purpose/Change: I Wanted to create an easy way of using runspaces to run concurrent tasks
  
.EXAMPLE
  This script is an example
#>

Using Module .\LLExec.psm1
using module .\LLTask.psm1
Using module .\LLRunspace.psm1
Using module .\LLState.psm1

function ScanNetworkTwoWay (){
    #_INIT 
    Write-host "`n`nScanNetworkTwoWay() => This method compare the time taking during a scan of the host network.`nThe first item is a measure-command of the sequential way, the second is a measure-command of the parallel way and the third is the result of the parallel way (just to show what it's look like).`nFor both methods the result is an hashtable @{Ip, PingResult})`n" -ForegroundColor Yellow
    $IpInArray = $(Get-NetIPConfiguration | where-object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected" }).IPv4Address.ipAddress.split('.')

    #_Sequential scan of the network
    $MeasureOne = Measure-Command{
        Function Test-Ping 
        {
            param($ip)
            trap {$false; continue}
            $timeout = 2000
            $object = New-Object system.Net.NetworkInformation.Ping
            (($object.Send($ip, $timeout)).Status -eq 'Success')
        }

        $Results = @()
        foreach ($byte in @(0..255)) {
            $ProgressPreference = 'SilentlyContinue'
            $ip = "$($IpInArray[0]).$($IpInArray[1]).$($IpInArray[2]).$($byte)"
            $Results += @{"ip" = $ip; "result" = $(Test-Ping $ip)}
        }
    }

    #_Parallel scan of the network    
    $MeasureTwo = Measure-Command{
        $Tasks = @()
        foreach ($byte in @(0..255)) {
            #_Prepare the tasks which will run in parallel
            $ip = "$($IpInArray[0]).$($IpInArray[1]).$($IpInArray[2]).$($byte)"
            $Name           = "$ip"
            $Description    = "Pinging ip $ip"
            $Script         = {
                Param($ip)
                
                return @{"ip" = $ip; "result" = $(Test-Ping $ip)}
            }
            $Params         = @($ip)
            $Task           = [LLTask]::New($Script, $Params, $Name, $Description)
            $Tasks          += $Task
        }
        #_Create the execution Object
        $Module = '.\ExampleModule_1.psm1'
        $Modules = @($Module)
        $Execution = [LLExec]::new($Host, $Modules, $Tasks)
        #_Execute the tasks
        $Execution.RunTasks()
        #_Wait the end of the execution foreach tasks
        $Execution.ReceiveTasks($true)
    }

    return @($MeasureOne, $MeasureTwo, $Execution)
}

$VerbosePreference = 'SilentlyContinue'
$ScanNetworkTwoWay =  ScanNetworkTwoWay
Write-host "`nSequential scan of the network : $($ScanNetworkTwoWay[0].TotalSeconds) seconds (ScanNetworkTwoWay[0])" -ForegroundColor Cyan
Write-host "Parallel scan of the network   : $($ScanNetworkTwoWay[1].TotalSeconds) seconds (ScanNetworkTwoWay[1])" -ForegroundColor Cyan
Write-host "Results gained by the parallel way (LLExec, ScanNetworkTwoWay[2]) : " -ForegroundColor Cyan
$ScanNetworkTwoWay[2]
Write-host "Example LLExec.Tasks (LLTask, ScanNetworkTwoWay[2].Tasks[0]) : " -ForegroundColor Cyan
$ScanNetworkTwoWay[2].Tasks[0]
Write-host "Example LLExec.Results (Object, ScanNetworkTwoWay[2].Results[0]) : " -ForegroundColor Cyan
$ScanNetworkTwoWay[2].Results[0]