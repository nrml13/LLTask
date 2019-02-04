<#
.SYNOPSIS
  This file store the class with represent the execution of all tasks.
  LLExec
.DESCRIPTION
  This class is the one wich will create a runspacepool to host the runspaces of all the tasks.
  It also provide a way to see the results of all tasks quickly.
  This class contains only two methods (exception of the constructor) :
    - RunTasks, To execute all the tasks in $Tasks
    - ReceiveTasks, To receive all the tasks which are terminated (you can wait them if you want). A message is displayed when a task is receive.

.PARAMETER ExecHost
    The host which will host the runspacepool. Usually use the variable $Host (just like in Runner.ps1).
.PARAMETER ModulesPaths
    It's an array of module path. These Path will be imported in the InitialSessionState which will be applied to the runspacepool.
.PARAMETER Tasks
    It's an array of LLTask. These task represents the action wich will be executed.
.PARAMETER Results
    It's null when the object is created.
    When you receive the tasks it's an array of object like Object(TaskId, TaskName, Errors, Results).
.PARAMETER Id
    Just a Guid to identify the LLExec object.
.INPUTS
  ExecHost, ModulesPaths, Tasks
.OUTPUTS
  Results
  And the results are accesible by the runspace object in direclty in the task
.NOTES
  Version:        0.4
  Author:         Nrml13
  Creation Date:  04/02/2019
  Purpose : I Wanted to create an easy way of using runspaces to run concurrent tasks. Ended up with runspacePool
  
.EXAMPLE
  Go see Runner.ps1
#>

using module .\LLTask.psm1

Class LLExec
{
    [ValidateNotNullOrEmpty()][System.Management.Automation.Host.PSHost] $ExecHost
    [String[]] $ModulesPaths
    [LLTask[]] $Tasks
    [Object[]] $Results
    [String] $Id
    
    LLExec ([System.Management.Automation.Host.PSHost] $ExecHost, [String[]] $ModulesPaths, [LLTask[]] $Tasks){
        $this.ModulesPaths = $ModulesPaths
        $this.Tasks = $Tasks
        $this.ExecHost = $ExecHost
        $this.Results = $null
        $this.Id = $(New-Guid).Guid
    }

    [Void] RunTasks (){
        Write-Verbose "LLExec - $($this.Id) - RunTasks () - Running the Tasks"

        #_Creation d'un InitialSessionState, il nous sert a importer les modules nécessaires à nos taches
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        if ($this.ModulesPaths)
        {
            $InitialSessionState.ImportPSModule($this.ModulesPaths)
        }
        
        #_Parametrage, Creation et Ouverture du RunspacePool
        $MinRunspace = 1
        $MaxRunspace = $this.Tasks.Count
        $RunspacePool = [runspacefactory]::CreateRunspacePool($MinRunspace, $MaxRunspace, $InitialSessionState, $this.ExecHost)
        $RunspacePool.Open()

        $this.Tasks.ForEach({
            #_Initialisation du runspace
            $_.InitRunspace($RunspacePool)

            #_Demarrage de l'instance powershell
            $_.Start()
        })
    }

    [Void] ReceiveTasks ([Boolean] $wait){
        Write-Verbose "LLExec - $($this.Id) - ReceiveTasks ([Boolean]) - Receiving the Tasks (wait = $wait)"

        if ($wait) {
            $Collected = 0
            $TasksToCollect = $($this.Tasks | where-object {$_.State.Code -eq 2})
            $NumberOfTasksToCollect = $TasksToCollect.count

            While ($Collected -ne $NumberOfTasksToCollect){
                foreach ($Task in $TasksToCollect) {
                    $ResultObject = $Task.Collect()
                    if ($ResultObject.toString() -ne 'ALREADY_COLLECTED' -and $ResultObject.toString() -ne 'NOT_YET'){

                        $PrecedentCollect = $this.Results | where-object {$_.TaskId -eq $Task.Id}
                        if ($PrecedentCollect){
                            $PrecedentCollect.Results = $ResultObject
                        }
                        else{
                            #$ResultObjectEnrich = @{'TaskId' = $Task.Id; 'TaskName' = $Task.Name; 'Results' = $ResultObject}
                            $ResultObjectEnrich = New-Object -TypeName PSObject 
                            $ResultObjectEnrich | add-member -membertype NoteProperty -name 'TaskId' -value $Task.Id
                            $ResultObjectEnrich | add-member -membertype NoteProperty -name 'TaskName' -value $Task.Name
                            $ResultObjectEnrich | add-member -membertype NoteProperty -name 'Errors' -value $Task.Runspace.Errors
                            $ResultObjectEnrich | add-member -membertype NoteProperty -name 'Results' -value $ResultObject
                                $this.Results += $ResultObjectEnrich
                        }
                        $Collected = $Collected + 1
                        Write-host "LLExec - $($this.Id) - ReceiveTasks ([Boolean]) - Collected : $Collected // NumberOfTasksToCollect : $NumberOfTasksToCollect" -ForegroundColor Green
                    }
                }
                Start-sleep -seconds 1
            }
        }
        else{
            foreach ($Task in $($this.Tasks | where-object {$_.State.Code -eq 2})) {
                $ResultObject = $Task.Collect()
                if ($ResultObject.toString() -ne 'ALREADY_COLLECTED'){

                    $PrecedentCollect = $this.Results | where-object {$_.TaskId -eq $Task.Id}
                    if ($PrecedentCollect){
                        $PrecedentCollect.Results = $ResultObject
                    }
                    else{
                        #$ResultObjectEnrich = @{"TaskId" = $Task.Id; "TaskName" = $Task.Name ;"Results" = $ResultObject}
                        $ResultObjectEnrich = New-Object -TypeName PSObject 
                        $ResultObjectEnrich | add-member -membertype NoteProperty -name 'TaskId' -value $Task.Id
                        $ResultObjectEnrich | add-member -membertype NoteProperty -name 'TaskName' -value $Task.Name
                        $ResultObjectEnrich | add-member -membertype NoteProperty -name 'Errors' -value $Task.RunspaceHasErrors
                        $ResultObjectEnrich | add-member -membertype NoteProperty -name 'Results' -value $ResultObject
                        $this.Results += $ResultObjectEnrich
                    }
                }
            }
        }
    }
}
