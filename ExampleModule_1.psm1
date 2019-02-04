<#
.SYNOPSIS
  This file is just an module used in the Runner.ps1.
  It's for demonstration.
  The function Test-Ping can be found at https://community.spiceworks.com/scripts/show/773-powershell-function-test-ping. 
  I just removed some comments. 

.EXAMPLE
  Go see Runner.ps1
#>
Function Test-Ping 
{
    param($ip)
    trap {$false; continue}
    $timeout = 2000
    $object = New-Object system.Net.NetworkInformation.Ping
    (($object.Send($ip, $timeout)).Status -eq 'Success')
}