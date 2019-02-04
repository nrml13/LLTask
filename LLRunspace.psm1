<#
.SYNOPSIS
  This file store the class with represent a Runspace.
  Usefull to not disperse informations.
  LLRunspace

.DESCRIPTION
  This class is using to represent the execution of a task.
  It contains the following methods :
    - InitPowershell, initialise the powershell instance and add the script to it.
    - AddArgument, add an argument to the powershell instance for using it in the script.
    - SetRunspacePool, Attribute the runspacepool to the powerhsell instance (the runspacepool is create in LLExec).
    - Start, start the powershell instance by calling BeginInvoke. The result of BeginInvoke is stored in IAsyncProcess.
    - Collect, retrieve the result of the runspace if it is completed. If the runspace is completed it store the result in Result and return it. It can return "NOT_YET" if it's not completed and "ALREADY_COLLECTED" if it's been already collected (Obviously ^^).
    
.PARAMETER Id
    Just a Guid to identify the LLRunspace object.
.PARAMETER Powershell
    The powershell instance, basicly the runspace.
.PARAMETER IAsyncProcess
    The IAsyncResult object that is returned when you run BeginInvoke() on the powershell instance. Usefull to retrieve easily the results.
.PARAMETER IsCollected
    If the results have already bean collected.
.PARAMETER Result
    The results of the runspace.
.PARAMETER Errors
    The errors which happened during execution.
.INPUTS
  usually this constructeur is used : LLRunspace()
.NOTES
  Version:        0.4
  Author:         Nrml13
  Creation Date:  04/02/2019
  Purpose : I Wanted to create an easy way of using runspaces to run concurrent tasks. Ended up with runspacePool
  
.EXAMPLE
  Go see Runner.ps1
#>

Class LLRunspace
{
    [System.IAsyncResult]$IAsyncProcess
    [Powershell]$Powershell
    [Object]$Result
    [Boolean]$IsCollected = $false
    [String] $Id
    [System.Object[]] $Errors
    
    #region Constructeurs
    LLRunspace([System.IAsyncResult]$IAsyncProcess, [Powershell]$Powershell, [Object]$Resultats){
        $this.IAsyncProcess = $IAsyncProcess
        $this.Powershell = $Powershell
        $this.Result = $Resultats
        $this.Id = $(New-Guid).Guid
    }
    LLRunspace([System.IAsyncResult]$IAsyncProcess, [Powershell]$Powershell){
        $this.IAsyncProcess = $IAsyncProcess
        $this.Powershell = $Powershell
        $this.Result = $null
        $this.Id = $(New-Guid).Guid
    }
    LLRunspace([Powershell]$Powershell){
        $this.Powershell = $Powershell
        $this.Result = $null
        $this.IAsyncProcess = $null
        $this.Id = $(New-Guid).Guid
    }
    LLRunspace(){
        $this.IAsyncProcess = $null
        $this.Powershell = $null
        $this.Result = $null
        $this.Id = $(New-Guid).Guid
    }
    #endregion

    [Void] InitPowershell ($Script){
        Write-Verbose "LLRunspace - $($this.Id) - InitPowershell ($-Script) - Powershell Instance Creation" 
        $this.Powershell = [powershell]::Create().AddScript($Script)
    }

    [Void] AddArgument ($Param){
        Write-Verbose "LLRunspace - $($this.Id) - AddArgument ($-Param) - Adding Argument"
        $this.Powershell.AddArgument($Param)
    }

    [Void] SetRunspacePool ($RunspacePool){
        Write-Verbose "LLRunspace - $($this.Id) - SetRunspacePool ($-RunspacePool) - Set the RunspacePool"
        $this.Powershell.RunspacePool = $RunspacePool
    }

    [Void] Start (){
        Write-Verbose "LLRunspace - $($this.Id) - Start () - Powershell Instance Invocation"
        $this.IAsyncProcess  = $this.Powershell.BeginInvoke()
    }

    [Object] Collect () {
        if ($this.IAsyncProcess.IsCompleted){
            if ($this.IsCollected -eq $false){
                if ($this.Powershell.HadErrors)
                {
                    Write-Warning "LLRunspace - $($this.Id) - Collect () - Des erreurs ont eut lieu lors de l'execution"
                    $this.Powershell.Streams.Error.forEach({
                        $this.Errors += $_
                    })
                }

                Try{
                    $this.Result = $this.Powershell.EndInvoke($this.IAsyncProcess)
                    $this.IsCollected = $true
                    Write-Verbose "LLRunspace - $($this.Id) - Collect () - Results collected, Dispose the powershell instance"
                    $this.Powershell.Dispose()
                    return $this.Result

                }Catch{
                    Write-Warning "LLRunspace - $($this.Id) - Collect () - Des erreurs ont eut lieu lors de la collection des résultats"
                    Throw $_
                }
            }
            else{
                return "ALREADY_COLLECTED"
            }
        }
        return "NOT_YET"
    }
}
