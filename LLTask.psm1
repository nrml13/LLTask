<#
.SYNOPSIS
  This file store the class with represent a tasks.
  LLTask

.DESCRIPTION
  This class is using to represent the actions which you want to execute.
  Concretely it's associated with a runspace.
  Contains 3 methods (some have different signature) :
    - SetState, change the state of the task.
    - InitRunspace, configure the runspace before starting it.
    - Start, start the task, it simply call LLRunspace.Start and change the state of the task when it's done.
    - Collect, return the result of the task if the runspace is completed.

.PARAMETER Id
    Just a Guid to identify the LLTask object.
.PARAMETER Name
    The name you give to your task.
.PARAMETER Description
    If you want to describe it.
.PARAMETER CreationDate
    The dateTime at which you created the task.
.PARAMETER State
    The state of the task. (go see LLState.psm1)
.PARAMETER Script
    The script which will be executed in the runspace.
    For the moment only ScriptBlock are supported, maybe path later.
.PARAMETER Params
    An array of objects which represents the parameters for the script.
.PARAMETER Runspace
    An LLRunspace object which represent the runspace of the task.
    Initialised when you run the task with LLExec.RunTasks().
.PARAMETER RunspaceHasErrors
    Boolean which says if the runspace has an errors during execution.

.INPUTS
  at least Script
.NOTES
  Version:        0.4
  Author:         Nrml13
  Creation Date:  04/02/2019
  Purpose : I Wanted to create an easy way of using runspaces to run concurrent tasks. Ended up with runspacePool
  
.EXAMPLE
  Go see Runner.ps1
#>

Using module .\LLRunspace.psm1
Using module .\LLState.psm1

Class LLTask
{
    [String] $Id
    [String] $Name
    [String] $Description
    [DateTime] $CreationDate

    [LLState] $State
    [ValidateNotNullOrEmpty()] [PSObject] $Script
    [PSObject[]] $Params

    [LLRunspace] $Runspace
    [Boolean] $RunspaceHasErrors = $false

    #region constructeurs
    LLTask( [PSObject] $Script, [PSObject[]] $Params, [string] $Name, [String] $Description ){

        $this.Params = $Params
        $this.Script = $Script
        $this.Name = $Name
        $this.Description = $Description

        $this.CreationDate = $(Get-Date)
        $this.Id = $(New-Guid).Guid
        $this.Runspace = [LLRunspace]::New()

        $this.SetState(0)
    }
    LLTask( [PSObject] $Script, [PSObject[]] $Params, [string] $Name){

        $this.Params = $Params
        $this.Script = $Script
        $this.Name = $Name
        $this.Description = $null

        $this.CreationDate = $(Get-Date)
        $this.Id = $(New-Guid).Guid
        $this.Runspace = [LLRunspace]::New()

        $this.SetState(0)
    }
    LLTask( [PSObject] $Script, [PSObject[]] $Params){

        $this.Params = $Params
        $this.Script = $Script
        $this.Name = $null
        $this.Description = $null

        $this.CreationDate = $(Get-Date)
        $this.Id = $(New-Guid).Guid
        $this.Runspace = [LLRunspace]::New()

        $this.SetState(0)
    }
    LLTask( [PSObject] $Script){

        $this.Params = $null
        $this.Script = $Script
        $this.Name = $null
        $this.Description = $null

        $this.CreationDate = $(Get-Date)
        $this.Id = $(New-Guid).Guid
        $this.Runspace = [LLRunspace]::New()

        $this.SetState(0)
    }
    #endregion

    [Void] SetState ([Int] $StateCode){
        $this.State = $([LLState]::Ref_State | where-object {$_.Code -eq $StateCode })
        Write-Verbose "LLTask - $($this.Id) - SetState ([Int]) - New state $($this.State)"
    }
    [Void] SetState ([String] $StateKey){
        $this.State = $([LLState]::Ref_State | where-object {$_.Key -eq $StateKey })
        Write-Verbose "LLTask - $($this.Id) - SetState ([String]) - New state $($this.State)"
    }

    [Void] InitRunspace ([System.Management.Automation.Runspaces.RunspacePool] $RunspacePool){
        Write-Verbose "LLTask - $($this.Id) - InitRunspace  ([System.Management.Automation.Runspaces.RunspacePool]) - Runspace Initialisation"

        #_Initialisation du runspace
        $this.Runspace.InitPowershell($this.Script)

        #_Ajout des paramètres du script
        If ($this.Params){
            Foreach ($Param in $this.Params)
            {
                $this.Runspace.AddArgument($Param)
            }
        }

        #_Attribution du runspacePool a l'instance powershell (même runspacepool pour toutes les taches)
        $this.Runspace.SetRunspacePool($RunspacePool)

        #_State = READY
        $this.SetState(1)
    }

    [Void] Start () {
        Write-Verbose "LLTask - $($this.Id) - Start () - Runspace Start"

        If ($this.State.Code -eq 1){
            #_Demarrage de l'instance powershell
            $this.Runspace.Start()

            #_State = RUNNING
            $this.SetState(2)
        }
    }

    [Object] Collect () {
        If ($this.State.Code -ne 4){
            Write-Verbose "LLTask - $($this.Id) - Collect () - Tentative de Récupèration de résultats"
            $Results = $this.Runspace.Collect()
            
            if ($this.Runspace.Errors -ne $false -and $this.Runspace.Errors -ne $null) {
                $this.RunspaceHasErrors = $true
            }

            if ($Results.toString() -ne 'ALREADY_COLLECTED' -and $Results.toString() -ne 'NOT_YET'){
                if ($this.State.Code -ne 4){
                    $this.SetState(4)
                }
            }

            return $Results
        }
        return 'ALREADY_COLLECTED'
    }
}